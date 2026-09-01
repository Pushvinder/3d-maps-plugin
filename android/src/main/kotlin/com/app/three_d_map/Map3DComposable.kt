package com.app.three_d_map

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.android.gms.maps3d.GoogleMap3D
import com.google.android.gms.maps3d.Map3DInitConfig
import com.google.android.gms.maps3d.Map3DView
import com.google.android.gms.maps3d.OnMap3DViewReadyCallback
import com.google.android.gms.maps3d.model.Map3DMode

/**
 * A Jetpack Compose wrapper for Google Maps 3D [Map3DView].
 *
 * @param modifier Modifier to be applied to the view layout.
 * @param initialLat Initial center latitude coordinate for the 3D map.
 * @param initialLng Initial center longitude coordinate for the 3D map.
 * @param initialAlt Initial altitude for the 3D map center.
 * @param heading Camera heading angle (0 to 360 degrees).
 * @param tilt Camera tilt angle (0 to 90 degrees).
 * @param range Distance from the target in meters.
 * @param mapMode Mode of the 3D map ([Map3DMode.HYBRID], [Map3DMode.SATELLITE], etc.).
 * @param onMapReady Callback invoked when the 3D map view is ready.
 * @param onError Callback invoked when an error occurs during map initialization.
 */
@Composable
fun Map3D(
    modifier: Modifier = Modifier,
    initialLat: Double = 38.544012,
    initialLng: Double = -107.670428,
    initialAlt: Double = 2427.6,
    heading: Double = 310.0,
    tilt: Double = 63.0,
    range: Double = 8266.0,
    @Map3DMode mapMode: Int = Map3DMode.HYBRID,
    onMapReady: (GoogleMap3D) -> Unit = {},
    onError: (Exception) -> Unit = {},
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val map3DView = remember {
        // Explicitly supply all 18 parameters to avoid calling synthetic default method create$default,
        // which was obfuscated in the play-services-maps3d release artifact and causes NoSuchMethodError.
        val config = Map3DInitConfig.create(
            centerLat = initialLat,
            centerLng = initialLng,
            centerAlt = initialAlt,
            heading = heading,
            tilt = tilt,
            roll = 0.0,
            range = range,
            minAltitude = 0.0,
            maxAltitude = 6.317E7,
            minHeading = 0.0,
            maxHeading = 360.0,
            minTilt = -90.0,
            maxTilt = 90.0,
            bounds = null,
            mapMode = mapMode,
            mapId = null,
            language = java.util.Locale.getDefault().language,
            region = java.util.Locale.getDefault().country,
        )
        Map3DView(context, config).apply {
            onCreate(null)
            getMap3DViewAsync(
                object : OnMap3DViewReadyCallback {
                    override fun onMap3DViewReady(googleMap3D: GoogleMap3D) {
                        onMapReady(googleMap3D)
                    }

                    override fun onError(error: Exception) {
                        onError(error)
                    }
                },
            )
        }
    }

    DisposableEffect(lifecycleOwner, map3DView) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> map3DView.onStart()
                Lifecycle.Event.ON_RESUME -> map3DView.onResume()
                Lifecycle.Event.ON_PAUSE -> map3DView.onPause()
                Lifecycle.Event.ON_STOP -> map3DView.onStop()
                Lifecycle.Event.ON_DESTROY -> map3DView.onDestroy()
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)

        if (lifecycleOwner.lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            map3DView.onStart()
        }
        if (lifecycleOwner.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) {
            map3DView.onResume()
        }

        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            map3DView.onDestroy()
        }
    }

    AndroidView(
        factory = { map3DView },
        modifier = modifier.fillMaxSize(),
    )
}
