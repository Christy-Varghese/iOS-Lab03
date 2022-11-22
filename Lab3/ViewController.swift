//
//  ViewController.swift
//  Lab3
//
//  Created by Christy Varghese on 2022-11-22.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate{
    
    private let locationManger = CLLocationManager()
//    private let locationManagerDelegate = MyLocationManagerDelegate()

    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherConditionImage: UIImageView!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var weatherConditionLabel: UILabel!
    
    var responseCode: Int = 0
    
    
    @IBOutlet weak var selectTempBtn: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchTextField.delegate = self
        locationManger.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Got the location", locations)
        if let location = locations.last{
            // find the location name from the coordinates
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if let error = error{
                    print("Error: \(error)")
                }
                else{
                    if let placemark = placemarks?.first{
                        print("Placemark: \(placemark)")
                        let city = placemark.locality ?? ""
                        self.locationLabel.text = "\(city)"
                        self.loadWeather(search: city)
                    }
                }
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    
    
   
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        if textField.returnKeyType == UIReturnKeyType.search{
            loadWeather(search: searchTextField.text)
        }
        return true
    }
    

    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        locationManger.requestWhenInUseAuthorization()
        locationManger.requestLocation()
    }
    
    private func loadWeather(search: String?){
        guard let search = search else{
            return
        }
        
        // 1: get Url
        guard let url = getUrl(searchFor: search) else{
            print("Could not get URL")
            return
        }
        
        // Step 2: Create URL Session
        let urlSession = URLSession.shared
        
        // Step 3: Create task for URL Session
        let dataTask = urlSession.dataTask(with: url) {data, response, error in
            // network call completed
            print("Network Call completed")
            
            guard error == nil else{
                print(error!)
                return
            }

            guard let data = data else{
                print("not data received")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data){
                
                self.responseCode = weatherResponse.current.condition.code
                self.demoImageConfig(resCode: self.responseCode)
                
                
                // to overcome the threading issue
                DispatchQueue.main.async { [self] in
                    if selectTempBtn.selectedSegmentIndex == 0{
                        self.temperatureLabel.text = "\(weatherResponse.current.temp_c)C"
                    }else{
                        self.temperatureLabel.text = "\(weatherResponse.current.temp_f)F"
                    }
                    self.weatherConditionLabel.text = weatherResponse.current.condition.text
                    self.locationLabel.text = weatherResponse.location.name                }
            }
        }
        
        
        // Step 4: Start Task
            dataTask.resume()
    }

    
    
    func getUrl(searchFor: String) -> URL?{
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "6e18732ac4c948538b7161234222211"
        let locationParam = "q=\(searchFor)"

        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&\(locationParam)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{
            return nil
        }
        
        // checking ...
        print(url)
        
       return URL(string: url)
    }
    
    func getLocationName(lat: Float, lon: Float){
        
    }
    
    // decoding the API
    private func parseJson(data: Data) -> WeatherResponse?{
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        }catch {
            print("Error Decoding..")
        }
        
        return weather
    }
    
    // mapping images according to the codes
    private func demoImageConfig(resCode: Int){
        
        let config = UIImage.SymbolConfiguration(paletteColors: [.white, .yellow, .cyan])
        self.weatherConditionImage.preferredSymbolConfiguration = config
        
        switch resCode{
        case 1000:
            self.weatherConditionImage.image = UIImage(systemName: "sun.max")
            break
        case 1003:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.sun")
            break
        case 1006:
            self.weatherConditionImage.image = UIImage(systemName: "cloud")
            break
        case 1009:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.sun.rain")
            break
        case 1030:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.fog")
            break
        case 1063:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.rain")
            break
        case 1066:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.snow")
            break
        case 1069:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.bolt.rain")
            break
        case 1114:
            self.weatherConditionImage.image = UIImage(systemName: "wind.snow")
            break
        case 1153:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.rain")
            break
        case 1183:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.rain")
        case 1195:
            self.weatherConditionImage.image = UIImage(systemName: "cloud.bolt.rain")
            break
        default:
            break
        }
    }
}


// structung accroding to the api
struct WeatherResponse: Decodable{
    var location: Location
    let current: Weather
}

struct Location: Decodable{
    let name: String
}

struct Weather: Decodable{
    let temp_c: Float
    let temp_f: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable{
    let text: String
    let code: Int
}
