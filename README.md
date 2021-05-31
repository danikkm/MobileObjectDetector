# MobileObjectDetector
## Inspired by
https://developer.apple.com/documentation/vision/recognizing_objects_in_live_capture

## Description
The app allows detecting objects in real-time by using compatible models*. 
Optimized YOLOv5s model            |  Non-optimized YOLOv5s model
:-------------------------:|:-------------------------:
 ![](https://user-images.githubusercontent.com/40919040/120038375-d83d4780-c00b-11eb-8538-4bac0b4b1649.png)   |  ![app_yolov5s](https://user-images.githubusercontent.com/40919040/120038397-dffcec00-c00b-11eb-952f-85c068c0074c.png)



#### Side note
ANE optimized models <https://github.com/ultralytics/yolov5/issues/2526> will run at full speed. The structure of the model should have the following things:
- Supported layers, see reference for conversion of the YOLOv5 models <https://github.com/danikkm/yolov5-coreml-tools>
- Image, IoU, and confidence - input features
- Confidence and coordinates - output features

### Key features
- Ability to select compute module (ANE, GPU+CPU, or CPU only)
- IoU and confidence thresholds adjustments
- Support for the front and back-facing cameras
- Ability to import .mlmodels from the Files app

### TODO
* Add support for other camera modules (other than iPhone 11 and later)
* Add description view for the currently selected model by tapping on the label
* Rewrite settings view controller with native table view
* Implement edit actions in the table view, refactor 
