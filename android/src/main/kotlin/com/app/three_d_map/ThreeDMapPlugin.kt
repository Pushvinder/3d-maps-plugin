package com.app.three_d_map

import android.app.Activity
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.findViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.findViewTreeSavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ThreeDMapPlugin */
class ThreeDMapPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "three_d_map")
        channel.setMethodCallHandler(this)

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "com.app.three_d_map/view",
            ThreeDMapViewFactory(flutterPluginBinding.binaryMessenger) { activity }
        )
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        bindLifecycleToWindow(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        bindLifecycleToWindow(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun bindLifecycleToWindow(act: Activity) {
        val lifecycleOwner = (act as? LifecycleOwner) ?: SimpleLifecycleOwner()
        val savedStateOwner = (act as? SavedStateRegistryOwner) ?: SimpleSavedStateRegistryOwner(lifecycleOwner)

        act.window?.decorView?.let { decorView ->
            if (decorView.findViewTreeLifecycleOwner() == null) {
                decorView.setViewTreeLifecycleOwner(lifecycleOwner)
            }
            if (decorView.findViewTreeSavedStateRegistryOwner() == null) {
                decorView.setViewTreeSavedStateRegistryOwner(savedStateOwner)
            }
        }
    }
}
