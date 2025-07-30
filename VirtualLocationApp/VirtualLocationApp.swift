import UIKit
import CoreLocation
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var locationManager: CLLocationManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
        
        setupLocationManager()
        return true
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("当前位置: \(location.coordinate)")
        
        // 发送位置更新通知
        NotificationCenter.default.post(
            name: .locationDidUpdate,
            object: nil,
            userInfo: ["location": location]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager?.startUpdatingLocation()
        case .denied, .restricted:
            print("位置权限被拒绝")
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
}

class MainViewController: UIViewController {
    private var mapView: MKMapView!
    private var locationManager: CLLocationManager!
    private var virtualLocationButton: UIButton!
    private var coordinateLabel: UILabel!
    private var currentLocationButton: UIButton!
    private var savedLocationsButton: UIButton!
    private var virtualLocation: CLLocationCoordinate2D?
    private var isVirtualLocationActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        loadSavedLocations()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 设置地图
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        view.addSubview(mapView)
        
        // 设置虚拟定位按钮
        virtualLocationButton = UIButton(type: .system)
        virtualLocationButton.setTitle("设置虚拟位置", for: .normal)
        virtualLocationButton.backgroundColor = .systemBlue
        virtualLocationButton.setTitleColor(.white, for: .normal)
        virtualLocationButton.layer.cornerRadius = 8
        virtualLocationButton.addTarget(self, action: #selector(setVirtualLocation), for: .touchUpInside)
        view.addSubview(virtualLocationButton)
        
        // 设置当前位置按钮
        currentLocationButton = UIButton(type: .system)
        currentLocationButton.setTitle("当前位置", for: .normal)
        currentLocationButton.backgroundColor = .systemGreen
        currentLocationButton.setTitleColor(.white, for: .normal)
        currentLocationButton.layer.cornerRadius = 8
        currentLocationButton.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        view.addSubview(currentLocationButton)
        
        // 设置保存位置按钮
        savedLocationsButton = UIButton(type: .system)
        savedLocationsButton.setTitle("保存的位置", for: .normal)
        savedLocationsButton.backgroundColor = .systemOrange
        savedLocationsButton.setTitleColor(.white, for: .normal)
        savedLocationsButton.layer.cornerRadius = 8
        savedLocationsButton.addTarget(self, action: #selector(showSavedLocations), for: .touchUpInside)
        view.addSubview(savedLocationsButton)
        
        // 设置坐标标签
        coordinateLabel = UILabel()
        coordinateLabel.text = "当前坐标: 未设置"
        coordinateLabel.textAlignment = .center
        coordinateLabel.backgroundColor = .systemGray6
        coordinateLabel.layer.cornerRadius = 8
        coordinateLabel.layer.masksToBounds = true
        coordinateLabel.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(coordinateLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        virtualLocationButton.translatesAutoresizingMaskIntoConstraints = false
        currentLocationButton.translatesAutoresizingMaskIntoConstraints = false
        savedLocationsButton.translatesAutoresizingMaskIntoConstraints = false
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -160),
            
            virtualLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            virtualLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            virtualLocationButton.widthAnchor.constraint(equalToConstant: 120),
            virtualLocationButton.heightAnchor.constraint(equalToConstant: 44),
            
            currentLocationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            currentLocationButton.widthAnchor.constraint(equalToConstant: 120),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 44),
            
            savedLocationsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            savedLocationsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            savedLocationsButton.widthAnchor.constraint(equalToConstant: 120),
            savedLocationsButton.heightAnchor.constraint(equalToConstant: 44),
            
            coordinateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coordinateLabel.bottomAnchor.constraint(equalTo: virtualLocationButton.topAnchor, constant: -10),
            coordinateLabel.widthAnchor.constraint(equalToConstant: 300),
            coordinateLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // 监听位置更新通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationUpdate),
            name: .locationDidUpdate,
            object: nil
        )
    }
    
    @objc private func handleLocationUpdate(_ notification: Notification) {
        guard let location = notification.userInfo?["location"] as? CLLocation else { return }
        
        if !isVirtualLocationActive {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
            coordinateLabel.text = "当前位置: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
    }
    
    @objc private func setVirtualLocation() {
        let alert = UIAlertController(title: "设置虚拟位置", message: "请输入经纬度坐标", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "纬度 (例如: 39.9042)"
            textField.keyboardType = .decimalPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "经度 (例如: 116.4074)"
            textField.keyboardType = .decimalPad
        }
        
        let confirmAction = UIAlertAction(title: "确定", style: .default) { _ in
            if let latText = alert.textFields?[0].text,
               let lonText = alert.textFields?[1].text,
               let latitude = Double(latText),
               let longitude = Double(lonText) {
                self.setVirtualLocation(latitude: latitude, longitude: longitude)
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func setVirtualLocation(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        virtualLocation = coordinate
        isVirtualLocationActive = true
        
        // 更新地图中心
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        // 添加标记
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "虚拟位置"
        annotation.subtitle = "纬度: \(latitude), 经度: \(longitude)"
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        // 更新标签
        coordinateLabel.text = "虚拟位置: \(latitude), \(longitude)"
        
        // 保存位置
        saveLocation(name: "虚拟位置", latitude: latitude, longitude: longitude)
        
        // 显示成功消息
        let alert = UIAlertController(title: "成功", message: "虚拟位置已设置", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showCurrentLocation() {
        isVirtualLocationActive = false
        locationManager.requestLocation()
        
        let alert = UIAlertController(title: "提示", message: "已切换到当前位置", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showSavedLocations() {
        let savedLocations = loadSavedLocations()
        
        let alert = UIAlertController(title: "保存的位置", message: nil, preferredStyle: .actionSheet)
        
        for location in savedLocations {
            let action = UIAlertAction(title: location.name, style: .default) { _ in
                self.setVirtualLocation(latitude: location.latitude, longitude: location.longitude)
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func saveLocation(name: String, latitude: Double, longitude: Double) {
        let location = SavedLocation(name: name, latitude: latitude, longitude: longitude)
        var savedLocations = loadSavedLocations()
        
        // 避免重复保存
        if !savedLocations.contains(where: { $0.name == name }) {
            savedLocations.append(location)
            
            if let data = try? JSONEncoder().encode(savedLocations) {
                UserDefaults.standard.set(data, forKey: "SavedLocations")
            }
        }
    }
    
    private func loadSavedLocations() -> [SavedLocation] {
        guard let data = UserDefaults.standard.data(forKey: "SavedLocations"),
              let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return []
        }
        return locations
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("当前位置: \(location.coordinate)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("位置权限被拒绝")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "VirtualLocationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}

struct SavedLocation: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
} 