import Flutter
import UIKit
import MapKit
import CoreLocation

struct iOSPlaceLocation {
    let name: String
    let lat: Double
    let lng: Double
    let alt: Double
    let heading: Double
    let tilt: Double
    let range: Double
}

private let PREDEFINED_LANDMARKS: [iOSPlaceLocation] = [
    iOSPlaceLocation(name: "Eiffel Tower", lat: 48.8584, lng: 2.2945, alt: 300.0, heading: 45.0, tilt: 65.0, range: 600.0),
    iOSPlaceLocation(name: "Mt. Everest", lat: 27.9881, lng: 86.9250, alt: 8848.0, heading: 180.0, tilt: 70.0, range: 12000.0),
    iOSPlaceLocation(name: "Grand Canyon", lat: 36.0544, lng: -112.1401, alt: 2100.0, heading: 300.0, tilt: 60.0, range: 5000.0),
    iOSPlaceLocation(name: "Statue of Liberty", lat: 40.6892, lng: -74.0445, alt: 100.0, heading: 15.0, tilt: 60.0, range: 400.0),
    iOSPlaceLocation(name: "Tokyo Tower", lat: 35.6586, lng: 139.7454, alt: 333.0, heading: 220.0, tilt: 65.0, range: 600.0),
    iOSPlaceLocation(name: "Taj Mahal", lat: 27.1751, lng: 78.0421, alt: 170.0, heading: 0.0, tilt: 60.0, range: 500.0),
    iOSPlaceLocation(name: "Burj Khalifa", lat: 25.1972, lng: 55.2744, alt: 828.0, heading: 90.0, tilt: 70.0, range: 1200.0),
    iOSPlaceLocation(name: "Colosseum", lat: 41.8902, lng: 12.4922, alt: 50.0, heading: 135.0, tilt: 60.0, range: 400.0),
]

class CustomMapAnnotation: NSObject, MKAnnotation {
    let id: String
    var coordinate: CLLocationCoordinate2D
    var altitude: Double
    var title: String?
    var snippet: String?
    var imageUrl: String
    var imageSize: Double
    var imageRadius: Double
    var image: UIImage?

    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        altitude: Double,
        title: String?,
        snippet: String?,
        imageUrl: String,
        imageSize: Double,
        imageRadius: Double
    ) {
        self.id = id
        self.coordinate = coordinate
        self.altitude = altitude
        self.title = title
        self.snippet = snippet
        self.imageUrl = imageUrl
        self.imageSize = imageSize
        self.imageRadius = imageRadius
        super.init()
    }
}

public class ThreeDMapView: NSObject, FlutterPlatformView, MKMapViewDelegate {
    private var mapView: MKMapView
    private var channel: FlutterMethodChannel
    private var annotationsMap = [String: CustomMapAnnotation]()
    private var isMapReadySent = false
    private var defaultImageSize: Double = 60.0
    private var defaultImageRadius: Double = 30.0

    private static let defaultImageUrl = "https://developers.google.com/static/maps/documentation/maps-3d/android-sdk/images/add-3d-model.png"

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.mapView = MKMapView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "com.app.three_d_map/view_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        self.mapView.delegate = self
        self.mapView.isPitchEnabled = true
        self.mapView.isRotateEnabled = true
        self.mapView.isZoomEnabled = true
        self.mapView.isScrollEnabled = true
        self.mapView.showsBuildings = true

        let creationParams = args as? [String: Any]
        let initialLat = (creationParams?["initialLat"] as? NSNumber)?.doubleValue ?? 38.544012
        let initialLng = (creationParams?["initialLng"] as? NSNumber)?.doubleValue ?? -107.670428
        let heading = (creationParams?["heading"] as? NSNumber)?.doubleValue ?? 310.0
        let tilt = (creationParams?["tilt"] as? NSNumber)?.doubleValue ?? 63.0
        let range = (creationParams?["range"] as? NSNumber)?.doubleValue ?? 8266.0
        let mapMode = (creationParams?["mapMode"] as? NSNumber)?.intValue ?? 0
        if let size = (creationParams?["imageSize"] as? NSNumber)?.doubleValue {
            self.defaultImageSize = size
            self.defaultImageRadius = (creationParams?["imageRadius"] as? NSNumber)?.doubleValue ?? (size / 2.0)
        } else if let radius = (creationParams?["imageRadius"] as? NSNumber)?.doubleValue {
            self.defaultImageRadius = radius
        }

        applyMapMode(mapMode)

        let center = CLLocationCoordinate2D(latitude: initialLat, longitude: initialLng)
        let camera = MKMapCamera(
            lookingAtCenter: center,
            fromDistance: range,
            pitch: CGFloat(tilt),
            heading: heading
        )
        self.mapView.setCamera(camera, animated: false)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.cancelsTouchesInView = false
        self.mapView.addGestureRecognizer(tapGesture)

        self.channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    public func view() -> UIView {
        return mapView
    }

    private func applyMapMode(_ modeInt: Int) {
        if #available(iOS 16.0, *) {
            switch modeInt {
            case 0: // HYBRID
                let config = MKHybridMapConfiguration(elevationStyle: .realistic)
                mapView.preferredConfiguration = config
            case 1: // SATELLITE
                let config = MKImageryMapConfiguration(elevationStyle: .realistic)
                mapView.preferredConfiguration = config
            case 2: // ROADMAP
                let config = MKStandardMapConfiguration(elevationStyle: .realistic)
                mapView.preferredConfiguration = config
            default:
                let config = MKHybridMapConfiguration(elevationStyle: .realistic)
                mapView.preferredConfiguration = config
            }
        } else {
            switch modeInt {
            case 0:
                mapView.mapType = .hybridFlyover
            case 1:
                mapView.mapType = .satelliteFlyover
            case 2:
                mapView.mapType = .standard
            default:
                mapView.mapType = .hybridFlyover
            }
        }
    }

    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let hitView = mapView.hitTest(point, with: nil)
        if hitView is MKAnnotationView || hitView?.superview is MKAnnotationView {
            return
        }

        let coord = mapView.convert(point, toCoordinateFrom: mapView)
        channel.invokeMethod("onMapClick", arguments: [
            "lat": coord.latitude,
            "lng": coord.longitude,
            "alt": 0.0,
            "placeId": NSNull()
        ])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "flyTo":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let lat = (args["lat"] as? NSNumber)?.doubleValue ?? 0.0
            let lng = (args["lng"] as? NSNumber)?.doubleValue ?? 0.0
            let heading = (args["heading"] as? NSNumber)?.doubleValue ?? 0.0
            let tilt = (args["tilt"] as? NSNumber)?.doubleValue ?? 60.0
            let range = (args["range"] as? NSNumber)?.doubleValue ?? 1000.0
            let durationMs = (args["durationMs"] as? NSNumber)?.doubleValue ?? 3000.0

            let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let camera = MKMapCamera(
                lookingAtCenter: center,
                fromDistance: range,
                pitch: CGFloat(tilt),
                heading: heading
            )

            UIView.animate(withDuration: durationMs / 1000.0, delay: 0, options: .curveEaseInOut) {
                self.mapView.camera = camera
            } completion: { _ in }

            result(true)

        case "setTilt":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
                return
            }
            let tilt = (args["tilt"] as? NSNumber)?.doubleValue ?? 0.0
            let durationMs = (args["durationMs"] as? NSNumber)?.doubleValue ?? 1500.0

            let currentCamera = mapView.camera
            let newCamera = MKMapCamera(
                lookingAtCenter: currentCamera.centerCoordinate,
                fromDistance: currentCamera.centerCoordinateDistance,
                pitch: CGFloat(tilt),
                heading: currentCamera.heading
            )

            UIView.animate(withDuration: durationMs / 1000.0, delay: 0, options: .curveEaseInOut) {
                self.mapView.camera = newCamera
            } completion: { _ in }

            result(true)

        case "addMarker":
            guard let params = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Marker arguments required", details: nil))
                return
            }
            let id = params["id"] as? String ?? "marker_\(Int(Date().timeIntervalSince1970 * 1000))"
            let lat = (params["lat"] as? NSNumber)?.doubleValue ?? 0.0
            let lng = (params["lng"] as? NSNumber)?.doubleValue ?? 0.0
            let alt = (params["alt"] as? NSNumber)?.doubleValue ?? 0.0
            let title = params["title"] as? String ?? ""
            let snippet = params["snippet"] as? String
            let imageUrl = params["imageUrl"] as? String ?? ""
            let sizeDp = (params["imageSize"] as? NSNumber)?.doubleValue ?? defaultImageSize
            let radiusDp = (params["imageRadius"] as? NSNumber)?.doubleValue ?? defaultImageRadius

            if let existing = annotationsMap[id] {
                mapView.removeAnnotation(existing)
                annotationsMap.removeValue(forKey: id)
            }

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let annotation = CustomMapAnnotation(
                id: id,
                coordinate: coord,
                altitude: alt,
                title: title,
                snippet: snippet,
                imageUrl: imageUrl,
                imageSize: sizeDp,
                imageRadius: radiusDp
            )

            annotationsMap[id] = annotation
            mapView.addAnnotation(annotation)

            let targetUrl = (!imageUrl.isEmpty && imageUrl != "null") ? imageUrl : ThreeDMapView.defaultImageUrl
            fetchAndApplyImage(url: targetUrl, annotation: annotation)

            result(id)

        case "removeMarker":
            guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Marker id required", details: nil))
                return
            }
            if let annotation = annotationsMap[id] {
                mapView.removeAnnotation(annotation)
                annotationsMap.removeValue(forKey: id)
            }
            result(true)

        case "clearMarkers":
            mapView.removeAnnotations(Array(annotationsMap.values))
            annotationsMap.removeAll()
            result(true)

        case "setMarkers":
            guard let args = call.arguments as? [String: Any],
                  let list = args["markers"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Markers list required", details: nil))
                return
            }
            mapView.removeAnnotations(Array(annotationsMap.values))
            annotationsMap.removeAll()

            for params in list {
                let id = params["id"] as? String ?? "marker_\(Int(Date().timeIntervalSince1970 * 1000))"
                let lat = (params["lat"] as? NSNumber)?.doubleValue ?? 0.0
                let lng = (params["lng"] as? NSNumber)?.doubleValue ?? 0.0
                let alt = (params["alt"] as? NSNumber)?.doubleValue ?? 0.0
                let title = params["title"] as? String ?? ""
                let snippet = params["snippet"] as? String
                let imageUrl = params["imageUrl"] as? String ?? ""
                let sizeDp = (params["imageSize"] as? NSNumber)?.doubleValue ?? defaultImageSize
                let radiusDp = (params["imageRadius"] as? NSNumber)?.doubleValue ?? defaultImageRadius

                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let annotation = CustomMapAnnotation(
                    id: id,
                    coordinate: coord,
                    altitude: alt,
                    title: title,
                    snippet: snippet,
                    imageUrl: imageUrl,
                    imageSize: sizeDp,
                    imageRadius: radiusDp
                )
                annotationsMap[id] = annotation
                mapView.addAnnotation(annotation)

                let targetUrl = (!imageUrl.isEmpty && imageUrl != "null") ? imageUrl : ThreeDMapView.defaultImageUrl
                fetchAndApplyImage(url: targetUrl, annotation: annotation)
            }
            result(true)

        case "searchLocation":
            guard let args = call.arguments as? [String: Any],
                  let query = args["query"] as? String,
                  !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Query string cannot be empty", details: nil))
                return
            }

            let trimmed = query.trimmingCharacters(in: .whitespaces)
            if let landmarkMatch = PREDEFINED_LANDMARKS.first(where: {
                $0.name.localizedCaseInsensitiveContains(trimmed) || trimmed.localizedCaseInsensitiveContains($0.name)
            }) {
                let placeMap: [String: Any] = [
                    "name": landmarkMatch.name,
                    "lat": landmarkMatch.lat,
                    "lng": landmarkMatch.lng,
                    "alt": landmarkMatch.alt,
                    "heading": landmarkMatch.heading,
                    "tilt": landmarkMatch.tilt,
                    "range": landmarkMatch.range
                ]
                let center = CLLocationCoordinate2D(latitude: landmarkMatch.lat, longitude: landmarkMatch.lng)
                let camera = MKMapCamera(
                    lookingAtCenter: center,
                    fromDistance: landmarkMatch.range,
                    pitch: CGFloat(landmarkMatch.tilt),
                    heading: landmarkMatch.heading
                )
                UIView.animate(withDuration: 3.0) {
                    self.mapView.camera = camera
                }
                result(placeMap)
                return
            }

            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(trimmed) { [weak self] (placemarks, error) in
                guard let self = self else { return }
                if let placemark = placemarks?.first, let location = placemark.location {
                    let name = placemark.name ?? placemark.locality ?? placemark.administrativeArea ?? trimmed
                    let placeMap: [String: Any] = [
                        "name": name,
                        "lat": location.coordinate.latitude,
                        "lng": location.coordinate.longitude,
                        "alt": 500.0,
                        "heading": 0.0,
                        "tilt": 55.0,
                        "range": 2500.0
                    ]
                    let center = location.coordinate
                    let camera = MKMapCamera(
                        lookingAtCenter: center,
                        fromDistance: 2500.0,
                        pitch: 55.0,
                        heading: 0.0
                    )
                    UIView.animate(withDuration: 3.0) {
                        self.mapView.camera = camera
                    }
                    result(placeMap)
                } else {
                    result(FlutterError(code: "NOT_FOUND", message: "Location '\(query)' not found", details: nil))
                }
            }

        case "setMapMode":
            guard let args = call.arguments as? [String: Any],
                  let modeInt = (args["mapMode"] as? NSNumber)?.intValue else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "mapMode argument required", details: nil))
                return
            }
            applyMapMode(modeInt)
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func fetchAndApplyImage(url urlString: String, annotation: CustomMapAnnotation) {
        loadImageFromUrl(urlString) { [weak self] image in
            guard let self = self else { return }
            if image == nil && urlString != ThreeDMapView.defaultImageUrl {
                self.loadImageFromUrl(ThreeDMapView.defaultImageUrl) { fallbackImage in
                    if let fb = fallbackImage {
                        self.applyImageToAnnotation(image: fb, annotation: annotation)
                    }
                }
            } else if let img = image {
                self.applyImageToAnnotation(image: img, annotation: annotation)
            }
        }
    }

    private func applyImageToAnnotation(image: UIImage, annotation: CustomMapAnnotation) {
        let sizeDp = CGFloat(annotation.imageSize)
        let radiusDp = CGFloat(annotation.imageRadius)
        let formattedImage = createCircularMarkerImage(image: image, sizeDp: sizeDp, radiusDp: radiusDp)

        annotation.image = formattedImage

        DispatchQueue.main.async { [weak self] in
            if let view = self?.mapView.view(for: annotation) {
                view.image = formattedImage
            }
        }
    }

    private func loadImageFromUrl(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 10.0

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }

    private func createCircularMarkerImage(image: UIImage, sizeDp: CGFloat, radiusDp: CGFloat) -> UIImage {
        let targetSize = CGSize(width: sizeDp, height: sizeDp)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: targetSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radiusDp)
            path.addClip()
            image.draw(in: rect)
        }
    }

    // MARK: - MKMapViewDelegate

    public func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if !isMapReadySent {
            isMapReadySent = true
            channel.invokeMethod("onMapReady", arguments: nil)
        }
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomMapAnnotation else {
            return nil
        }

        let identifier = "CustomMapAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = customAnnotation
        }

        if let img = customAnnotation.image {
            annotationView?.image = img
        } else {
            let sizeDp = CGFloat(customAnnotation.imageSize)
            annotationView?.frame = CGRect(x: 0, y: 0, width: sizeDp, height: sizeDp)
        }

        return annotationView
    }

    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomMapAnnotation else { return }
        channel.invokeMethod("onMarkerClick", arguments: [
            "markerId": annotation.id,
            "lat": annotation.coordinate.latitude,
            "lng": annotation.coordinate.longitude,
            "alt": annotation.altitude,
            "title": (annotation.title as Any),
            "snippet": (annotation.snippet as Any)
        ])
    }
}
