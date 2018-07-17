//
//  ViewController.swift
//  Indoor-Positioning
//
//  Created by 41 on 2018/4/8.
//  Copyright © 2018年 41. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreBluetooth
import JavaScriptCore
import AVFoundation

public var webview_Comment:String = ""
public var webview_Position:Int = 0
public var webview_PredicPosition:String = ""
public var webview_OpenCamera:Bool = false
public var webview_ScanQRCode:Bool = false
public var webview_QRCodeString:String = ""

@objc protocol JavaScriptFuncProtocol: JSExport {
    func openCamera(_ Comment: String, _ Position: Int, _ PredictPosition: String)
    func ScanQRCode()
}
class JavaScriptMethod : NSObject, JavaScriptFuncProtocol {
    func openCamera(_ Comment: String, _ Position: Int, _ PredictPosition: String) {
        webview_OpenCamera = true
        webview_Comment = Comment
        webview_Position = Position
        webview_PredicPosition = PredictPosition
    }
    func ScanQRCode () {
        webview_ScanQRCode = true
    }
}

class customPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(pinTitle:String, pinSubTitle:String, location:CLLocationCoordinate2D) {
        self.title = pinTitle
        self.subtitle = pinSubTitle
        self.coordinate = location
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIWebViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate  {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var webView: UIWebView!
    
    let LM = CLLocationManager()
    let uuid = UUID(uuidString: "D9F08C92-6C39-486F-A245-D65D36695AF3") // 太和光
    
    var alert_cnt:Int? = 0
    
    /** PickerView **/
    var list = [String]()
    var building: String = ""
    
    /** DEFINITION **/
    var FirstTimeEnter:Bool = true
    var CollectEnable:Bool = true
    var AverageEnable:Bool = false
    var CollectCount:Int = 0
    var BeaconsCount:Int = 0
    var ResultMessage:String = ""
    var Beacon_Rssi:[Int] = []
    var collectTimer:Int = 5 //second
    
    /** 戶外判斷 **/
    var OutsideCount:Int = 0
    
    /** 建築判斷 **/
    var index:Int = 0
    
    /** 各建築 Beacon 數量 **/
    let EE01_Beacon_Quantity = 4
    let IB01_Beacon_Quantity = 6
    let IB11_Beacon_Quantity = 4
    var Beacon_Quantity:[Int] = []
    
    /** 各建築定義之 Major **/
    let EE01_Major = 7051 //1
    let IB01_Major = 18 //2
    let IB11_Major = 28 //3
    var Building_Major:[Int] = []
    
    /** 各建築 K **/
    let EE01_K = 12
    let IB01_K = 3
    let IB11_K = 2
    var K:[Int] = []
    
    /** QRCode **/
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /** Definition Array **/
        Beacon_Quantity = [EE01_Beacon_Quantity,IB01_Beacon_Quantity,IB11_Beacon_Quantity]
        Building_Major = [EE01_Major,IB01_Major,IB11_Major]
        K = [EE01_K,IB01_K,IB11_K]
        
        /** picker view setting **/
        list.append("請選擇您要前往的地點")
        list.append("研揚大樓 TR")
        list.append("國際大樓 IB")
        list.append("電資學院 EE")
        
        /** QR Code Setting **/
        QRCodeSetting()
        
        /** WebView Setting **/
        let url = Bundle.main.url(forResource: "index", withExtension: "html")
        webView.loadRequest(URLRequest(url: url!))
        webView.delegate = self
        
        let jsContext = self.webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext
        jsContext?.setObject(JavaScriptMethod(), forKeyedSubscript: "javaScriptCallToSwift" as (NSCopying & NSObjectProtocol)?)
        
        /** Beacon Scan **/
        LM.requestAlwaysAuthorization()
        LM.delegate = self
        LM.distanceFilter = kCLLocationAccuracyNearestTenMeters
        LM.desiredAccuracy = kCLLocationAccuracyBest
    
        let region = CLBeaconRegion(proximityUUID: uuid!, identifier: "MyRegion")
        LM.startMonitoring(for: region)
    }
    
    /** WebView_OpenCamera **/
    func openPhoneCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            // 設定相片來源為相機
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            // 開啟相機介面
            show(imagePicker, sender: self)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // 取得拍下來的照片
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        upload_image(image: image)
        // 將照片存檔
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    
    func upload_image(image: UIImage) {
        
        /** Upload Image **/
        UploadRequest(comment: webview_Comment, choosePos: webview_Position, fixPredictPlaceName: webview_PredicPosition, image: image)
        /** Return Upload Successful **/
        webView.stringByEvaluatingJavaScript(from: "CameraCallBack()")
    }
    
    /** Upload Request **/
    func UploadRequest(comment:String, choosePos:Int, fixPredictPlaceName:String, image:UIImage)
    {
        let url = URL(string: "http://www.oort.com.tw/bohan/test/fixSystem/user_upload_image.php?comment=\(comment)&choosePos=\(choosePos)&fixPredictPlaceName=\(fixPredictPlaceName)")
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let image_data = UIImagePNGRepresentation(image)
        
        if(image_data == nil)
        {
            return
        }
        
        let body = NSMutableData()
        
        let fname = "test.png"
        let mimetype = "image/png"
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"test\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("hi\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image_data!)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        request.httpBody = body as Data
        let session = URLSession.shared
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {            (
            data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            
            print(dataString)
        }
        task.resume()
    }
    func generateBoundaryString() -> String
    {
        return "Boundary-\(UUID().uuidString)"
    }
    
    /** WebView_ScanQRCode **/
    func QRCodeSetting() {
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
    }
    /** Enable Scan QR Code **/
    func ScanQRCode() {
         videoPreviewLayer?.isHidden = false
        // Start video capture.
        captureSession.startRunning()
        
        // Initialize QR Code Frame to highlight the QR code
        
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
        
    }
    /** QR Code Upload to Server **/
    func QRCodeStopScanningAndUpload() {
        captureSession.stopRunning()
        webView.stringByEvaluatingJavaScript(from: "QRCodeScanCallBack(\"\(webview_QRCodeString)\")")
        videoPreviewLayer?.isHidden = true
        qrCodeFrameView?.isHidden = true
    }
    
    /** Model Loading **/
    func loadModel (area: Int) -> [[String]] {
        /** Open the txt file **/
        switch area {
        case 0:
            let ee1fDataPath = Bundle.main.path(forResource: "ee1f_train_2.6s", ofType: "txt")
            let ee1fData = try? String(contentsOfFile: ee1fDataPath!)
            /** Parse the txt / split the lines with the character `\n` and create an array **/
            let rows = ee1fData!.characters.split(separator: "\r\n").map { String($0) }
            /** split values in row with the character `,` and create an array **/
            let trainData = rows.map { rows -> [String] in
                let split = rows.characters.split(separator: ",")
                return split.map { String($0) }
            }
            return trainData
        case 1:
            let ib1fDataPath = Bundle.main.path(forResource: "ib1f_train_3.2s", ofType: "txt")
            let ib1fData = try? String(contentsOfFile: ib1fDataPath!)
            /** Parse the txt / split the lines with the character `\n` and create an array **/
            let rows = ib1fData!.characters.split(separator: "\n").map { String($0) }
            /** split values in row with the character `,` and create an array **/
            let trainData = rows.map { rows -> [String] in
                let split = rows.characters.split(separator: ",")
                return split.map { String($0) }
            }
            return trainData
        default:
            let ib11fDataPath = Bundle.main.path(forResource: "ib11f_train_2.6s", ofType: "txt")
            let ib11fData = try? String(contentsOfFile: ib11fDataPath!)
            /** Parse the txt / split the lines with the character `\n` and create an array **/
            let rows = ib11fData!.characters.split(separator: "\n").map { String($0) }
            /** split values in row with the character `,` and create an array **/
            let trainData = rows.map { rows -> [String] in
                let split = rows.characters.split(separator: ",")
                return split.map { String($0) }
            }
            return trainData
        }
    }
    
    /** Cosine similarity **/
    func cosineSim(A: [String], B: [String]) -> Double {
        return dot(A: A, B: B) / (magnitude(A: A) * magnitude(A: B))
    }
    
    /** Dot Product **/
    func dot(A: [String], B: [String]) -> Double {
        var x: Double = 0
        for i in 0...A.count-2 {
            x += Double(A[i])! * Double(B[i])!
        }
        return x
    }
    
    /** Vector Magnitude **/
    func magnitude(A: [String]) -> Double {
        var x: Double = 0
        for i in 0...A.count-2 {
            x += Double(A[i])! * Double(A[i])!
        }
        return sqrt(x)
    }
    
    /** KNN Predict **/
    func KNN(data: [String], trainSet: [[String]], trainSet_Class:[[String]], K:Int) -> String {
        var DistanceArray: [[Any]] = Array(repeating: Array(repeating: 0.0, count: 2), count: trainSet.count)
        // for i in 1...trainSet.count
        for i in 0...trainSet.count-1 {
            DistanceArray[i][0] = cosineSim(A:trainSet[i] ,B:data)
            DistanceArray[i][1] = trainSet_Class[i][Beacon_Quantity[index]]
            DistanceArray.append(DistanceArray[i])
        }
        let AfterSort_Array = DistanceArray.sorted { ($0[0] as? Double)! > ($1[0] as? Double)! }
        var cnt:Int = 0
        var TopIndex:[String] = Array(repeating: "", count: K)
        var TopCnt:[Int] = Array(repeating: 0, count: K)
        var Judge:Bool = false

        for i in 0...K-1 {
            if cnt == 0 {
                TopIndex[cnt] = AfterSort_Array[i][1] as! String
                TopCnt[cnt] += 1
                cnt += 1
            }
            else {
                for j in 0...cnt-1 {
                    if AfterSort_Array[i][1] as! String == TopIndex[j] {
                        TopCnt[j] += 1
                        Judge = true
                    }
                    else {
                    }
                }
                if Judge {
                    Judge = false
                }
                else {
                    TopIndex[cnt] = AfterSort_Array[i][1] as! String
                    TopCnt[cnt] += 1
                    cnt += 1
                    Judge = false
                }
            }
        }
        
        let max = TopCnt.max()
        let result = TopCnt.index(of: max!)
        
        return TopIndex[result!]
    }
    
    /** Picker View **/
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        building = list[row]
    }
    
    /** WebView Did Finish Load **/
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Webview Did Finish Load!")
    }
    
    /** MapView Route Setting **/
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation:CLLocation = locations[0] as CLLocation
        
        // 1.代理
        self.mapView.delegate = self
        
        print("\(currentLocation.coordinate.latitude)")
        print("\(currentLocation.coordinate.longitude)")
        
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        var pinTitle: String = ""
        var pinSubTitle: String = ""
        
        switch building {
            case "研揚大樓 TR":
                latitude = 25.014952
                longitude = 121.542859
                pinTitle = "TR"
                pinSubTitle = "研揚大樓"
            case "國際大樓 IB":
                latitude = 25.013084
                longitude = 121.540246
                pinTitle = "IB"
                pinSubTitle = "國際大樓"
            case "電資學院 EE":
                latitude = 25.012085
                longitude = 121.541656
                pinTitle = "EE"
                pinSubTitle = "電資學院"
            default:
                //設定為 alert action
                let alertController = UIAlertController(title: "錯誤", message: "您必須選擇一個地標在按搜尋", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) {
                    (action) in
                    self.dismiss (animated: true, completion: nil)
                }
                //增加"OK"按鍵
                alertController.addAction(okAction)
                //顯示提醒
                show(alertController, sender: self)
        }
        
        /** 2.設置地點的經緯度 **/
        let sourceLocation = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        let destinationLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        /** clear mapView **/
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        /** 3.增加 annotation 的標題和位置 **/
        let destinationPin = customPin(pinTitle: pinTitle, pinSubTitle: pinSubTitle, location: destinationLocation)
        
        /** 4.新增 annotation **/
        self.mapView.addAnnotation(destinationPin)
        
        /** 5.建立包含座標的對像 **/
        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation)
        
        /** 6.使用 MKDirectionsRequest 計算路徑 **/
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        /** 交通方式 **/
        directionRequest.transportType = .walking
        
        
        /** 7.使用折線在地圖上繪製路徑 **/
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionRequest = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            let route = directionRequest.routes[0]
            self.mapView.add(route.polyline, level: .aboveLabels)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
        
        LM.stopUpdatingLocation()
    }
    
    /** Create Route **/
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    /** Enter CLRegion **/
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Enter \(region.identifier)")
    }
    /** Exit CLRegion **/
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exit \(region.identifier)")
    }
    /** Monitoring Mode **/
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        print("StartMonitoring")
        let region = CLBeaconRegion(proximityUUID: uuid!, identifier: "MyRegion")
        LM.startRangingBeacons(in: region)
    }
    
    /** didRangeBeacons **/
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard beacons.count > 0 else {
            OutsideCount += 1
            if OutsideCount >= 3 {
                FirstTimeEnter = true
                webView.isHidden = true
                mapView.isHidden = false
            }
            print("no any beacon")
            return
        }
        OutsideCount = 0
        webView.isHidden = false
        mapView.isHidden = true
        
        if webview_OpenCamera {
            openPhoneCamera()
            webview_OpenCamera = false
        }
        
        if webview_ScanQRCode {
            ScanQRCode()
            webview_ScanQRCode = false
        }
        
        if FirstTimeEnter {
            FirstTimeEnter = false
            switch Int(beacons[0].major) {
            case EE01_Major:
                index = 0
                Beacon_Rssi = Array(repeating: 0, count: EE01_Beacon_Quantity)
            case IB01_Major:
                index = 1
                Beacon_Rssi = Array(repeating: 0, count: IB01_Beacon_Quantity)
            case IB11_Major:
                index = 2
                Beacon_Rssi = Array(repeating: 0, count: IB11_Beacon_Quantity)
            default:
                index = 0
                Beacon_Rssi = Array(repeating: 0, count: EE01_Beacon_Quantity)
            }
        }
        
        if CollectEnable {
            if CollectCount == collectTimer {
                print(" ")
                AverageEnable = true
                CollectEnable = false
            }
            else if BeaconsCount != beacons.count {
                initialSet(BeaconQuantity: Beacon_Quantity[index])
            }
            else {
                CollectCount = CollectCount + 1
            }
        }
        
        /** Indoor Positioning **/
        webView.stringByEvaluatingJavaScript(from: "showIndoorImage(\(index))")
        if AverageEnable {
            for i in 0..<Beacon_Rssi.count {
                Beacon_Rssi[i] = Beacon_Rssi[i] / collectTimer
                if Beacon_Rssi[i] == 0 {
                    Beacon_Rssi[i] = -120
                }
            }
            print("Beacon  訊號平均強度: \(Beacon_Rssi)")
            let AverageRssiString = Beacon_Rssi.map {
                String($0)
            }
            let trainData = loadModel(area: index)
            let predictArea = KNN(data: AverageRssiString, trainSet: trainData, trainSet_Class: trainData, K: K[index])
            
            if predictArea == "0" {
                webView.isHidden = true
                mapView.isHidden = false
            } else {
                webView.isHidden = false
                mapView.isHidden = true
            }
            
            if index == 0 {
                webView.stringByEvaluatingJavaScript(from: "showDirection('\(predictArea)')")
            } else {
                webView.stringByEvaluatingJavaScript(from: "showPosition('\(predictArea)')")
            }
            initialSet(BeaconQuantity: Beacon_Quantity[index])
            print("\nPredict Area: \(predictArea)\n")
        }
        print("Beacon  偵測數量: \(beacons.count) 個")
        for i in 0...beacons.count-1 {
            if beacons[i].rssi == 0 {
                Beacon_Rssi[Int(beacons[i].minor)-1] = (Beacon_Rssi[Int(beacons[i].minor)-1] + -120)
            } else {
                Beacon_Rssi[Int(beacons[i].minor)-1] = (Beacon_Rssi[Int(beacons[i].minor)-1] + beacons[i].rssi)
            }
            print("Beacon\(i) 主編號 (Major): \(beacons[i].major)")
            print("Beacon\(i) 副編號 (Minor): \(beacons[i].minor)")
            print("Beacon\(i) 訊號量 (RSSI): \(beacons[i].rssi) dB")
        }
        BeaconsCount = beacons.count
    }
    
    /** 初始設定 **/
    func initialSet(BeaconQuantity: Int) {
        FirstTimeEnter = true
        AverageEnable = false
        CollectEnable = true
        CollectCount = 0
        for i in 0..<BeaconQuantity {
            Beacon_Rssi[i] = 0
        }
    }
    
    /** 尋找路線 Button **/
    @IBAction func searchBuilding(_ sender: Any) {
        LM.startUpdatingLocation()
    }
}

/** QR Code Scanning Extension **/
extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                webview_QRCodeString = metadataObj.stringValue!
                QRCodeStopScanningAndUpload()
            }
        }
    }
}
