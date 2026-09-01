package com.app.three_d_map

/*
 Reference code provided by user for working image popover implementation in 3D Map:

 val imageUrl = "https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png"

 coroutineScope.launch {
     val bitmap = loadBitmapFromUrl(imageUrl)
     if (bitmap != null && marker != null) {
         try {
             val popoverView = createMarkerImageView(context, bitmap)
             val popoverOptions = PopoverOptions().apply {
                 setContent(popoverView)
                 setPositionAnchor(marker)
                 setAutoCloseEnabled(false)
                 setAutoPanEnabled(false)
             }
             map.addPopover(popoverOptions)
         } catch (e: Exception) {
             Log.e("MainActivity", "Error adding image popover to 3D map", e)
         }
     }
 }
*/
