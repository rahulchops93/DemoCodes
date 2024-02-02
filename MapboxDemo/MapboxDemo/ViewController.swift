//
//  ViewController.swift
//  MapboxDemo
//
//  Created by Rahul Chopra on 21/11/23.
//

import UIKit
import MapboxMaps
import MapboxCoreMaps

private enum Constants {
    static let BLUE_ICON_ID = "blue"
    static let SOURCE_ID = "source_id"
    static let LAYER_ID = "water-label"
    static let TERRAIN_SOURCE = "TERRAIN_SOURCE"
    static let TERRAIN_URL_TILE_RESOURCE = "mapbox://mapbox.mapbox-terrain-dem-v1"
    static let MARKER_ID_PREFIX = "view_annotation_"
    static let SELECTED_ADD_COEF_PX: CGFloat = 50
}

class ViewController: UIViewController {
    
    internal var mapView: MapView!
    private lazy var markerHeight: CGFloat = 50//image.size.height
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let myResourceOptions = ResourceOptions(accessToken: "pk.eyJ1IjoiZmFybWZsb3ciLCJhIjoiY2xubHRheDUxMjI3YzJrbnNpcHdqZHY2MCJ9.yGc7WLrI_g6JI2Z09and_w")
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions)
        mapView = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMapClick)))
         
        self.view.addSubview(mapView)
    }

    @objc private func onMapClick(_ sender: UITapGestureRecognizer) {
        let screenPoint = sender.location(in: mapView)
        let queryOptions = RenderedQueryOptions(layerIds: [Constants.LAYER_ID], filter: nil)
        mapView.mapboxMap.queryRenderedFeatures(with: screenPoint, options: queryOptions) { [weak self] result in
            switch result {
            case .success(let queriedFeatures):
                if let self = self,
                let feature = queriedFeatures.first?.feature,
                let id = feature.identifier,
                case let .string(idString) = id,
                   let viewAnnotations = self.mapView.viewAnnotations {
                    if let annotationView = viewAnnotations.view(forFeatureId: idString) {
                        let visible = viewAnnotations.options(for: annotationView)?.visible ?? true
                        try? viewAnnotations.update(annotationView, options: ViewAnnotationOptions(visible: !visible))
                    } else {
                        let markerCoordinates: CLLocationCoordinate2D
                        if let geometry = feature.geometry, case let Geometry.point(point) = geometry {
                            markerCoordinates = point.coordinates
                        } else {
                            markerCoordinates = self.mapView.mapboxMap.coordinate(for: screenPoint)
                        }
                        self.addViewAnnotation(at: markerCoordinates, withMarkerId: idString)
                    }
                }
            case .failure(let err):
                print(err)
            }
        }
    }
    
    // Add a view annotation at a specified location and optionally bind it to an ID of a marker
    private func addViewAnnotation(at coordinate: CLLocationCoordinate2D, withMarkerId markerId: String? = nil) {
        let options = ViewAnnotationOptions(
            geometry: Point(coordinate),
            width: 128,
            height: 64,
            associatedFeatureId: markerId,
            allowOverlap: false,
            anchor: .bottom
        )
        let annotationView = AnnotationView(frame: CGRect(x: 0, y: 0, width: 128, height: 64))
        annotationView.title = String(format: "lat=%.2f\nlon=%.2f", coordinate.latitude, coordinate.longitude)
        annotationView.delegate = self
        try? mapView.viewAnnotations.add(annotationView, options: options)
        
        // Set the vertical offset of the annotation view to be placed above the marker
        try? mapView.viewAnnotations.update(annotationView, options: ViewAnnotationOptions(offsetY: markerHeight))
    }
}


extension ViewController: AnnotationViewDelegate {
    func annotationViewDidSelect(_ annotationView: AnnotationView) {
        guard let options = self.mapView.viewAnnotations.options(for: annotationView) else { return }
        
        let updateOptions = ViewAnnotationOptions(
            width: (options.width ?? 0.0) + Constants.SELECTED_ADD_COEF_PX,
            height: (options.height ?? 0.0) + Constants.SELECTED_ADD_COEF_PX,
            selected: true
        )
        try? self.mapView.viewAnnotations.update(annotationView, options: updateOptions)
    }
    
    func annotationViewDidUnselect(_ annotationView: AnnotationView) {
        guard let options = self.mapView.viewAnnotations.options(for: annotationView) else { return }
        
        let updateOptions = ViewAnnotationOptions(
            width: (options.width ?? 0.0) - Constants.SELECTED_ADD_COEF_PX,
            height: (options.height ?? 0.0) - Constants.SELECTED_ADD_COEF_PX,
            selected: false
        )
        try? self.mapView.viewAnnotations.update(annotationView, options: updateOptions)
    }
    
    // Handle the actions for the button clicks inside the `SampleView` instance
    func annotationViewDidPressClose(_ annotationView: AnnotationView) {
        mapView.viewAnnotations.remove(annotationView)
    }
}
