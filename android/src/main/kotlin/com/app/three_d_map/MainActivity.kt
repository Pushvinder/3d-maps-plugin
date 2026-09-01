package com.app.three_d_map

import android.content.Context
import android.location.Geocoder
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.app.three_d_map.theme.Google3dMapTheme
import com.google.android.gms.maps3d.GoogleMap3D
import com.google.android.gms.maps3d.model.Map3DMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class PlaceLocation(
    val name: String,
    val lat: Double,
    val lng: Double,
    val alt: Double = 500.0,
    val heading: Double = 0.0,
    val tilt: Double = 60.0,
    val range: Double = 1500.0,
)

val PREDEFINED_LANDMARKS = listOf(
    PlaceLocation("Eiffel Tower", 48.8584, 2.2945, 300.0, 45.0, 65.0, 600.0),
    PlaceLocation("Mt. Everest", 27.9881, 86.9250, 8848.0, 180.0, 70.0, 12000.0),
    PlaceLocation("Grand Canyon", 36.0544, -112.1401, 2100.0, 300.0, 60.0, 5000.0),
    PlaceLocation("Statue of Liberty", 40.6892, -74.0445, 100.0, 15.0, 60.0, 400.0),
    PlaceLocation("Tokyo Tower", 35.6586, 139.7454, 333.0, 220.0, 65.0, 600.0),
    PlaceLocation("Taj Mahal", 27.1751, 78.0421, 170.0, 0.0, 60.0, 500.0),
    PlaceLocation("Burj Khalifa", 25.1972, 55.2744, 828.0, 90.0, 70.0, 1200.0),
    PlaceLocation("Colosseum", 41.8902, 12.4922, 50.0, 135.0, 60.0, 400.0),
)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            Google3dMapTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Map3DScreen(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }
}

@Composable
fun Map3DScreen(
    modifier: Modifier = Modifier,
    initialLat: Double = 38.544012,
    initialLng: Double = -107.670428,
    initialAlt: Double = 2427.6,
    heading: Double = 310.0,
    tilt: Double = 63.0,
    range: Double = 8266.0,
    @Map3DMode mapMode: Int = Map3DMode.HYBRID,
    onMapReady: (GoogleMap3D) -> Unit = {},
    onMapClick: (Double, Double, Double, String?) -> Unit = { _, _, _, _ -> },
    onError: (Exception) -> Unit = {},
) {
    Map3D(
        modifier = modifier.fillMaxSize(),
        initialLat = initialLat,
        initialLng = initialLng,
        initialAlt = initialAlt,
        heading = heading,
        tilt = tilt,
        range = range,
        mapMode = mapMode,
        onMapReady = { googleMap3D ->
            onMapReady(googleMap3D)
            googleMap3D.setMap3DClickListener { location, placeId ->
                onMapClick(location.latitude, location.longitude, location.altitude, placeId)
            }
        },
        onError = { error ->
            onError(error)
            Log.e("MainActivity", "Error loading 3D map", error)
        },
    )
}

@Suppress("DEPRECATION")
suspend fun searchPlace(context: Context, query: String): PlaceLocation? = withContext(Dispatchers.IO) {
    val trimmed = query.trim()
    if (trimmed.isEmpty()) return@withContext null

    val landmarkMatch = PREDEFINED_LANDMARKS.find {
        it.name.contains(trimmed, ignoreCase = true) || trimmed.contains(it.name, ignoreCase = true)
    }
    if (landmarkMatch != null) return@withContext landmarkMatch

    try {
        val geocoder = Geocoder(context)
        val addresses = geocoder.getFromLocationName(trimmed, 1)
        if (!addresses.isNullOrEmpty()) {
            val address = addresses[0]
            val name = address.featureName ?: address.locality ?: address.adminArea ?: trimmed
            return@withContext PlaceLocation(
                name = name,
                lat = address.latitude,
                lng = address.longitude,
                alt = 500.0,
                heading = 0.0,
                tilt = 55.0,
                range = 2500.0,
            )
        }
    } catch (e: Exception) {
        Log.e("MainActivity", "Geocoder error for search '$query'", e)
    }
    return@withContext null
}
