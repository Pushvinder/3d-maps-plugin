package com.app.three_d_map

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Outline
import android.graphics.drawable.GradientDrawable
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.ViewParent
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.platform.AbstractComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.findViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.findViewTreeSavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import com.app.three_d_map.theme.Google3dMapTheme
import com.google.android.gms.maps3d.GoogleMap3D
import com.google.android.gms.maps3d.OnCameraChangedListener
import com.google.android.gms.maps3d.Popover
import com.google.android.gms.maps3d.model.Camera
import com.google.android.gms.maps3d.model.FlyToOptions
import com.google.android.gms.maps3d.model.LatLngAltitude
import com.google.android.gms.maps3d.model.Map3DMode
import com.google.android.gms.maps3d.model.PopoverOptions
import com.google.android.gms.maps3d.model.PopoverStyle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal class SimpleLifecycleOwner : LifecycleOwner {
    private val registry = LifecycleRegistry(this).apply {
        currentState = Lifecycle.State.RESUMED
    }
    override val lifecycle: Lifecycle get() = registry
}

internal class SimpleSavedStateRegistryOwner(
    private val lifecycleOwner: LifecycleOwner
) : SavedStateRegistryOwner {
    private val controller = SavedStateRegistryController.create(this)

    init {
        controller.performAttach()
        controller.performRestore(null)
    }

    override val lifecycle: Lifecycle
        get() = lifecycleOwner.lifecycle

    override val savedStateRegistry: SavedStateRegistry
        get() = controller.savedStateRegistry
}

/**
 * Custom [AbstractComposeView] that ensures lifecycle and saved state owners
 * are attached to itself and all ancestor views (including FlutterView) BEFORE Jetpack Compose's
 * [onAttachedToWindow] runs and attempts to create a window recomposer.
 */
class FlutterComposeView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val activity: Activity? = null
) : AbstractComposeView(context, attrs, defStyleAttr) {

    private val contentState = mutableStateOf<(@Composable () -> Unit)?>(null)

    @Suppress("RedundantVisibilityModifier")
    protected override var shouldCreateCompositionOnAttachedToWindow: Boolean = false
        private set

    fun setContent(content: @Composable () -> Unit) {
        shouldCreateCompositionOnAttachedToWindow = true
        contentState.value = content
        if (isAttachedToWindow) {
            createComposition()
        }
    }

    @Composable
    override fun Content() {
        contentState.value?.invoke()
    }

    override fun onAttachedToWindow() {
        bindLifecycleToAncestors()
        super.onAttachedToWindow()
    }

    fun bindLifecycleToAncestors() {
        val targetActivity = activity ?: context.findActivity()

        val lifecycleOwner: LifecycleOwner = (targetActivity as? LifecycleOwner)
            ?: (context as? LifecycleOwner)
            ?: context.findLifecycleOwner()
            ?: findViewTreeLifecycleOwner()
            ?: (parent as? View)?.findViewTreeLifecycleOwner()
            ?: rootView?.findViewTreeLifecycleOwner()
            ?: targetActivity?.window?.decorView?.findViewTreeLifecycleOwner()
            ?: SimpleLifecycleOwner()

        val savedStateOwner: SavedStateRegistryOwner = (targetActivity as? SavedStateRegistryOwner)
            ?: (context as? SavedStateRegistryOwner)
            ?: context.findSavedStateRegistryOwner()
            ?: findViewTreeSavedStateRegistryOwner()
            ?: (parent as? View)?.findViewTreeSavedStateRegistryOwner()
            ?: rootView?.findViewTreeSavedStateRegistryOwner()
            ?: targetActivity?.window?.decorView?.findViewTreeSavedStateRegistryOwner()
            ?: SimpleSavedStateRegistryOwner(lifecycleOwner)

        setViewTreeLifecycleOwner(lifecycleOwner)
        setViewTreeSavedStateRegistryOwner(savedStateOwner)

        var current: ViewParent? = parent
        while (current is View) {
            if (current.findViewTreeLifecycleOwner() == null) {
                current.setViewTreeLifecycleOwner(lifecycleOwner)
            }
            if (current.findViewTreeSavedStateRegistryOwner() == null) {
                current.setViewTreeSavedStateRegistryOwner(savedStateOwner)
            }
            current = current.parent
        }
    }
}

private fun Context.findActivity(): Activity? {
    var ctx = this
    while (ctx is ContextWrapper) {
        if (ctx is Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}

private fun Context.findLifecycleOwner(): LifecycleOwner? {
    var ctx = this
    while (ctx is ContextWrapper) {
        if (ctx is LifecycleOwner) return ctx
        ctx = ctx.baseContext
    }
    return null
}

private fun Context.findSavedStateRegistryOwner(): SavedStateRegistryOwner? {
    var ctx = this
    while (ctx is ContextWrapper) {
        if (ctx is SavedStateRegistryOwner) return ctx
        ctx = ctx.baseContext
    }
    return null
}

class ThreeDMapView(
    private val context: Context,
    private val activity: Activity?,
    private val id: Int,
    messenger: BinaryMessenger,
    creationParams: Map<String, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.app.three_d_map/view_$id")
    private val composeView: FlutterComposeView = FlutterComposeView(context, activity = activity)
    private var googleMap3D: GoogleMap3D? = null
    private val scope = CoroutineScope(Dispatchers.Main)
    private val popovers3DMap = mutableMapOf<String, Popover>()

    private val initialLat = (creationParams?.get("initialLat") as? Number)?.toDouble() ?: 38.544012
    private val initialLng = (creationParams?.get("initialLng") as? Number)?.toDouble() ?: -107.670428
    private val initialAlt = (creationParams?.get("initialAlt") as? Number)?.toDouble() ?: 2427.6
    private val heading = (creationParams?.get("heading") as? Number)?.toDouble() ?: 310.0
    private val tilt = (creationParams?.get("tilt") as? Number)?.toDouble() ?: 63.0
    private val range = (creationParams?.get("range") as? Number)?.toDouble() ?: 8266.0
    private val defaultImageSize = (creationParams?.get("imageSize") as? Number)?.toDouble() ?: 60.0
    private val defaultImageRadius = (creationParams?.get("imageRadius") as? Number)?.toDouble() ?: (defaultImageSize / 2.0)
    private val mapMode = when ((creationParams?.get("mapMode") as? Number)?.toInt()) {
        0, Map3DMode.HYBRID -> Map3DMode.HYBRID
        1, Map3DMode.SATELLITE -> Map3DMode.SATELLITE
        2, Map3DMode.ROADMAP -> Map3DMode.ROADMAP
        else -> Map3DMode.HYBRID
    }

    init {
        channel.setMethodCallHandler(this)

        val originalHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(Thread.UncaughtExceptionHandler { thread: Thread, throwable: Throwable ->
            val msg = (throwable as java.lang.Throwable).localizedMessage ?: ""
            if (msg.contains("onAuthenticationFailed") || msg.contains("MapConfigs") || thread.name.contains("punchpool")) {
                Log.e("ThreeDMapView", "Google Maps 3D Auth Exception caught safely", throwable)
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    channel.invokeMethod("onError", mapOf("error" to "Google Maps 3D Authentication Failed. Please check your API Key in AndroidManifest.xml."))
                }
            } else {
                originalHandler?.uncaughtException(thread, throwable)
            }
        })

        composeView.setViewCompositionStrategy(
            ViewCompositionStrategy.DisposeOnDetachedFromWindow
        )

        composeView.bindLifecycleToAncestors()

        composeView.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                composeView.bindLifecycleToAncestors()
            }

            override fun onViewDetachedFromWindow(v: View) {}
        })

        composeView.setOnTouchListener { _: View, _: MotionEvent ->
            try {
                googleMap3D?.getCamera()?.let { camera ->
                    notifyCameraMove(camera)
                }
            } catch (e: Throwable) {
                Log.e("ThreeDMapView", "Error handling touch event", e)
            }
            false
        }

        composeView.setContent {
            Google3dMapTheme {
                Map3D(
                    initialLat = initialLat,
                    initialLng = initialLng,
                    initialAlt = initialAlt,
                    heading = heading,
                    tilt = tilt,
                    range = range,
                    mapMode = mapMode,
                    onMapReady = { map ->
                        this@ThreeDMapView.googleMap3D = map
                        try {
                            map.setCameraChangedListener(object : OnCameraChangedListener {
                                override fun onCameraChanged(camera: Camera) {
                                    notifyCameraMove(camera)
                                }
                            })
                        } catch (e: Exception) {
                            Log.e("ThreeDMapView", "Error setting camera change listener", e)
                        }
                        channel.invokeMethod("onMapReady", null)
                    },
                    onError = { error ->
                        channel.invokeMethod("onError", mapOf("error" to error.localizedMessage))
                    }
                )
            }
        }
    }

    override fun getView(): View = composeView

    private var lastCameraState: String = ""

    private fun notifyCameraMove(camera: Camera) {
        try {
            val center = camera.getCenter() ?: return
            val lat = center.latitude
            val lng = center.longitude
            val alt = center.altitude
            val headingVal = camera.getHeading()?.toDouble() ?: 0.0
            val tiltVal = camera.getTilt()?.toDouble() ?: 0.0
            val rangeVal = camera.getRange()?.toDouble() ?: 0.0

            val stateKey = "$lat,$lng,$alt,$headingVal,$tiltVal,$rangeVal"
            if (stateKey == lastCameraState) return
            lastCameraState = stateKey

            val params = mapOf(
                "lat" to lat,
                "lng" to lng,
                "alt" to alt,
                "heading" to headingVal,
                "tilt" to tiltVal,
                "range" to rangeVal
            )

            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    channel.invokeMethod("onCameraMove", params)
                } catch (e: Throwable) {
                    Log.e("ThreeDMapView", "Error invoking onCameraMove", e)
                }
            }
        } catch (e: Throwable) {
            Log.e("ThreeDMapView", "Error in notifyCameraMove", e)
        }
    }

    companion object {
        private const val DEFAULT_IMAGE_URL = "https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png"
    }

    fun addImageMarkerTo3DMap(
        map: GoogleMap3D,
        lat: Double,
        lng: Double,
        alt: Double,
        title: String,
        imageUrl: String,
        id: String,
        imageSize: Double? = null,
        imageRadius: Double? = null
    ) {
        val sizeDp = imageSize ?: defaultImageSize
        val radiusDp = imageRadius ?: defaultImageRadius
        val targetUrl = if (imageUrl != "" && imageUrl != "null") imageUrl else DEFAULT_IMAGE_URL

        scope.launch {
            var bitmap = loadBitmapFromUrl(targetUrl)
            if (bitmap == null && targetUrl != DEFAULT_IMAGE_URL) {
                // Fallback to working Google 3D model test image if custom URL fails to download
                bitmap = loadBitmapFromUrl(DEFAULT_IMAGE_URL)
            }

            if (bitmap != null) {
                try {
                    // Remove existing popover if re-adding with same id
                    popovers3DMap[id]?.remove()

                    val onMarkerClickListener = View.OnClickListener {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            channel.invokeMethod(
                                "onMarkerClick",
                                mapOf(
                                    "markerId" to id,
                                    "lat" to lat,
                                    "lng" to lng,
                                    "alt" to alt,
                                    "title" to title
                                )
                            )
                        }
                    }
                    val popoverView = createMarkerImageView(context, bitmap, sizeDp, radiusDp, onMarkerClickListener)

                    val popoverStyle = PopoverStyle()
                        .setPadding(0f)
                        .setBackgroundColor(Color.TRANSPARENT)
                        .setBorderRadius(0f)

                    val popoverOptions = PopoverOptions().apply {
                        setContent(popoverView)
                        setPositionAnchor(LatLngAltitude(lat, lng, alt))
                        setAutoCloseEnabled(false)
                        setAutoPanEnabled(false)
                        setPopoverStyle(popoverStyle)
                    }
                    val popover = map.addPopover(popoverOptions)
                    if (popover != null) {
                        popovers3DMap[id] = popover
                    }
                } catch (e: Exception) {
                    Log.e("Map3D", "Error adding image popover to 3D map", e)
                }
            }
        }
    }

    private suspend fun loadBitmapFromUrl(urlString: String): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val url = URL(urlString)
            val connection = url.openConnection() as HttpURLConnection
            connection.setRequestProperty(
                "User-Agent",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.doInput = true
            connection.connect()

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                BitmapFactory.decodeStream(connection.inputStream)
            } else {
                Log.e("Map3D", "HTTP Error loading image: ${connection.responseCode} ${connection.responseMessage}")
                null
            }
        } catch (e: Exception) {
            Log.e("Map3D", "Error downloading image bitmap from $urlString", e)
            null
        }
    }

    private fun createMarkerImageView(
        context: Context,
        bitmap: Bitmap,
        sizeDp: Double,
        radiusDp: Double,
        onClickListener: View.OnClickListener? = null
    ): View {
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt()
        val radiusPx = (radiusDp * density).toFloat()

        val frameLayout = FrameLayout(context).apply {
            layoutParams = ViewGroup.LayoutParams(sizePx, sizePx)
            clipToOutline = true
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, radiusPx)
                }
            }
            if (onClickListener != null) {
                setOnClickListener(onClickListener)
            }
        }

        val imageView = ImageView(context).apply {
            setImageBitmap(bitmap)
            scaleType = ImageView.ScaleType.CENTER_CROP
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            if (onClickListener != null) {
                setOnClickListener(onClickListener)
            }
        }

        frameLayout.addView(imageView)
        return frameLayout
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "flyTo" -> {
                val map = googleMap3D
                if (map == null) {
                    result.error("UNAVAILABLE", "GoogleMap3D is not ready yet", null)
                    return
                }
                val lat = (call.argument<Number>("lat"))?.toDouble() ?: 0.0
                val lng = (call.argument<Number>("lng"))?.toDouble() ?: 0.0
                val alt = (call.argument<Number>("alt"))?.toDouble() ?: 500.0
                val headingVal = (call.argument<Number>("heading"))?.toDouble() ?: 0.0
                val tiltVal = (call.argument<Number>("tilt"))?.toDouble() ?: 60.0
                val rangeVal = (call.argument<Number>("range"))?.toDouble() ?: 1000.0
                val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 3000L

                val center = LatLngAltitude(lat, lng, alt)
                val camera = Camera(center, headingVal, tiltVal, 0.0, rangeVal)
                val flyToOptions = FlyToOptions(camera, durationMs)
                map.flyCameraTo(flyToOptions)
                result.success(true)
            }
            "setTilt" -> {
                val map = googleMap3D
                if (map == null) {
                    result.error("UNAVAILABLE", "GoogleMap3D is not ready yet", null)
                    return
                }
                val targetTilt = (call.argument<Number>("tilt"))?.toDouble() ?: 0.0
                val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 1500L
                val currentCamera = map.getCamera()
                if (currentCamera != null) {
                    val newCamera = Camera(
                        currentCamera.getCenter(),
                        currentCamera.getHeading(),
                        targetTilt,
                        currentCamera.getRoll(),
                        currentCamera.getRange()
                    )
                    map.flyCameraTo(FlyToOptions(newCamera, durationMs))
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "Camera is not available", null)
                }
            }
            "addMarker" -> {
                val map = googleMap3D
                val params = call.arguments as? Map<String, Any?>
                if (map != null && params != null) {
                    val id = params["id"] as? String ?: "marker_${System.currentTimeMillis()}"
                    val lat = (params["lat"] as? Number)?.toDouble() ?: 0.0
                    val lng = (params["lng"] as? Number)?.toDouble() ?: 0.0
                    val alt = (params["alt"] as? Number)?.toDouble() ?: 0.0
                    val title = params["title"] as? String ?: ""
                    val imageUrl = params["imageUrl"] as? String ?: ""
                    val imageSize = (params["imageSize"] as? Number)?.toDouble()
                    val imageRadius = (params["imageRadius"] as? Number)?.toDouble()

                    addImageMarkerTo3DMap(map, lat, lng, alt, title, imageUrl, id, imageSize, imageRadius)
                    result.success(id)
                } else {
                    result.error("UNAVAILABLE", "GoogleMap3D not ready or params invalid", null)
                }
            }
            "removeMarker" -> {
                val map = googleMap3D
                val id = call.argument<String>("id")
                if (map != null && id != null) {
                    popovers3DMap[id]?.remove()
                    popovers3DMap.remove(id)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Marker id required", null)
                }
            }
            "clearMarkers" -> {
                val map = googleMap3D
                if (map != null) {
                    popovers3DMap.values.forEach { it.remove() }
                    popovers3DMap.clear()
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "GoogleMap3D not ready", null)
                }
            }
            "setMarkers" -> {
                val map = googleMap3D
                @Suppress("UNCHECKED_CAST")
                val markersList = call.argument<List<Map<String, Any?>>>("markers")
                if (map != null && markersList != null) {
                    popovers3DMap.values.forEach { it.remove() }
                    popovers3DMap.clear()
                    for (params in markersList) {
                        val id = params["id"] as? String ?: "marker_${System.currentTimeMillis()}"
                        val lat = (params["lat"] as? Number)?.toDouble() ?: 0.0
                        val lng = (params["lng"] as? Number)?.toDouble() ?: 0.0
                        val alt = (params["alt"] as? Number)?.toDouble() ?: 0.0
                        val title = params["title"] as? String ?: ""
                        val imageUrl = params["imageUrl"] as? String ?: ""
                        val imageSize = (params["imageSize"] as? Number)?.toDouble()
                        val imageRadius = (params["imageRadius"] as? Number)?.toDouble()

                        addImageMarkerTo3DMap(map, lat, lng, alt, title, imageUrl, id, imageSize, imageRadius)
                    }
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "GoogleMap3D not ready", null)
                }
            }
            "searchLocation" -> {
                val query = call.argument<String>("query")
                if (query.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "Query string cannot be empty", null)
                    return
                }
                scope.launch {
                    val place = searchPlace(context, query)
                    if (place != null) {
                        val placeMap = mapOf(
                            "name" to place.name,
                            "lat" to place.lat,
                            "lng" to place.lng,
                            "alt" to place.alt,
                            "heading" to place.heading,
                            "tilt" to place.tilt,
                            "range" to place.range
                        )
                        googleMap3D?.let { map ->
                            val center = LatLngAltitude(place.lat, place.lng, place.alt)
                            val camera = Camera(center, place.heading, place.tilt, 0.0, place.range)
                            map.flyCameraTo(FlyToOptions(camera, 3000L))
                        }
                        result.success(placeMap)
                    } else {
                        result.error("NOT_FOUND", "Location '$query' not found", null)
                    }
                }
            }
            "setMapMode" -> {
                val map = googleMap3D
                if (map != null) {
                    val modeInt = (call.argument<Number>("mapMode"))?.toInt() ?: 0
                    val mode = when (modeInt) {
                        0, Map3DMode.HYBRID -> Map3DMode.HYBRID
                        1, Map3DMode.SATELLITE -> Map3DMode.SATELLITE
                        2, Map3DMode.ROADMAP -> Map3DMode.ROADMAP
                        else -> Map3DMode.HYBRID
                    }
                    map.setMapMode(mode)
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "GoogleMap3D is not ready yet", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun Context.findActivity(): Activity? {
        var ctx = this
        while (ctx is ContextWrapper) {
            if (ctx is Activity) return ctx
            ctx = ctx.baseContext
        }
        return null
    }
}
