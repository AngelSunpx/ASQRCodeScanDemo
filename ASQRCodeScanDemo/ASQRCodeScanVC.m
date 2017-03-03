//
//  ASQRCodeScanVC.m
//
//  Created by AngelSunpx on 7/6/2016.
//  Copyright © 2016 Sunpx. All rights reserved.
//

#import "ASQRCodeScanVC.h"

#define kMainScreenHeight   [[UIScreen mainScreen] bounds].size.height
#define kMainScreenWidth    [[UIScreen mainScreen] bounds].size.width
#define SCANVIEW_EdgeTop    40.0
#define SCANVIEW_EdgeLeft   50.0
#define TINTCOLOR_ALPHA     0.2 //浅色透明度
#define DARKCOLOR_ALPHA     0.5 //深色透明度

@interface ASQRCodeScanVC ()
{
    UIView               *_QrCodeline;
    NSTimer              *_timer;
    UIView               *_scanView;     //设置扫描画面
    UIButton             *openButton;    //开关闪光灯
    BOOL                 hasOutput;      //是否已识别
    AVAudioSession      *customSoundSession;
    AVAudioPlayer       *customSoundPlayer;
}

@end

@implementation ASQRCodeScanVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.title = @"扫描";
    
    [self setupCamera];
    
    //初始化扫描界面
    [self setScanView];
    [self createTimer];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopTimer];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupCamera
{
    // Device
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    self.output = [[AVCaptureMetadataOutput alloc]init];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    if ([self.session canAddInput:self.input])
    {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output])
    {
        [self.session addOutput:self.output];
    }
    
    // 条码类型
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    // Preview
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = self.view.bounds;
    [self.view.layer addSublayer:self.preview];
    
    self.output.rectOfInterest = CGRectMake(SCANVIEW_EdgeTop/self.view.bounds.size.height,
                                            SCANVIEW_EdgeLeft/self.view.bounds.size.width,
                                            (kMainScreenWidth - 2 * SCANVIEW_EdgeLeft)/self.view.bounds.size.height,
                                            (kMainScreenWidth - 2 * SCANVIEW_EdgeLeft)/self.view.bounds.size.width);//CGRectMake（y的起点/屏幕的高，x的起点/屏幕的宽，扫描的区域的高/屏幕的高，扫描的区域的宽/屏幕的宽）
    
    // Start
    [self.session startRunning];
}

//二维码的扫描区域
- (void)setScanView
{
    _scanView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight - 64)];
    _scanView.backgroundColor = [UIColor clearColor];
    //最上部view
    UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0 ,0 ,kMainScreenWidth ,SCANVIEW_EdgeTop)];
    upView.alpha = TINTCOLOR_ALPHA ;
    upView.backgroundColor = [UIColor blackColor];
    [_scanView addSubview :upView];
    //左侧的view
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0 ,SCANVIEW_EdgeTop ,SCANVIEW_EdgeLeft ,kMainScreenWidth - 2 * SCANVIEW_EdgeLeft)];
    leftView.alpha = TINTCOLOR_ALPHA;
    leftView.backgroundColor = [UIColor blackColor];
    [_scanView addSubview:leftView];
    
    /******************中间扫描区域****************************/
    UIImageView *scanCropView=[[UIImageView alloc]initWithFrame:CGRectMake(SCANVIEW_EdgeLeft ,SCANVIEW_EdgeTop ,kMainScreenWidth - 2 * SCANVIEW_EdgeLeft ,kMainScreenWidth - 2 * SCANVIEW_EdgeLeft)];
    scanCropView.layer.borderColor = [UIColor greenColor].CGColor;
    scanCropView.layer.borderWidth = 2.0;
    scanCropView.backgroundColor = [UIColor clearColor];
    [_scanView addSubview :scanCropView];
    
    //右侧的view
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(kMainScreenWidth - SCANVIEW_EdgeLeft ,SCANVIEW_EdgeTop ,SCANVIEW_EdgeLeft , kMainScreenWidth - 2 * SCANVIEW_EdgeLeft)];
    rightView.alpha = TINTCOLOR_ALPHA;
    rightView.backgroundColor = [UIColor blackColor];
    [_scanView addSubview:rightView];
    
    //底部view
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0 ,kMainScreenWidth - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop ,kMainScreenWidth , kMainScreenHeight - (kMainScreenWidth - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop) - 64)];
    downView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:TINTCOLOR_ALPHA];
    [_scanView addSubview:downView];
    
    //用于说明的label
    UILabel *labIntroudction= [[UILabel alloc] init];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.frame = CGRectMake (0 ,5 ,kMainScreenWidth ,20);
    labIntroudction.numberOfLines = 1;
    labIntroudction.font = [UIFont systemFontOfSize:13.0];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.textColor = [UIColor whiteColor];
    labIntroudction.text = @"将二维码放入框内，即可自动扫描";
    [downView addSubview:labIntroudction];
    UIView *darkView = [[UIView alloc] initWithFrame:CGRectMake(0 ,downView.frame.size.height - 80.0 ,kMainScreenWidth ,80.0)];
    darkView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:DARKCOLOR_ALPHA];
    [downView addSubview :darkView];
    
    //用于开关灯操作的button
    openButton=[[UIButton alloc] initWithFrame:CGRectMake(30 ,20 ,kMainScreenWidth-60 ,40.0)];
    [openButton setTitle:@"开启闪光灯" forState:UIControlStateNormal];
    [openButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    openButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [openButton setBackgroundImage:[UIImage imageNamed:@"registerBtn"] forState:UIControlStateNormal];
    openButton.titleLabel.font = [UIFont systemFontOfSize:22.0];
    [openButton addTarget:self action:@selector(openLight) forControlEvents:UIControlEventTouchUpInside];
    [darkView addSubview:openButton];
    
    //画中间的基准线
    _QrCodeline = [[UIView alloc] initWithFrame:CGRectMake(SCANVIEW_EdgeLeft ,SCANVIEW_EdgeTop ,kMainScreenWidth - 2 * SCANVIEW_EdgeLeft ,2)];
    _QrCodeline.backgroundColor = [UIColor greenColor];
    [_scanView addSubview:_QrCodeline];
    
    [self.view addSubview:_scanView];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    
    if (!hasOutput && [metadataObjects count] >0) {
        hasOutput = YES;
        
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
        
        UIAlertController *alertControll = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:stringValue];
        [hogan addAttribute:NSFontAttributeName
                      value:[UIFont systemFontOfSize:14.0]
                      range:NSMakeRange(0, [[hogan string] length])];
        [alertControll setValue:hogan forKey:@"attributedTitle"];
        //取消按钮
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            hasOutput = NO;
            [self startReading];
        }];
        [alertControll addAction:cancelButton];
        [self presentViewController:alertControll animated:YES completion:nil];
        
        [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
    }else{
        NSLog(@"扫描失败，请重试调整角度");
        return;
    }
    //扫描成功提示音
    NSError *error = nil;
    if (customSoundSession == nil) {
        customSoundSession = [AVAudioSession sharedInstance];
        [customSoundSession setCategory:AVAudioSessionCategoryPlayback error:&error];
        [customSoundSession setActive:YES error:&error];
    }
    
    if (customSoundPlayer == nil) {
        NSString *path = [[NSBundle mainBundle]pathForResource:@"qrcode" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        customSoundPlayer = nil;
        customSoundPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
    }
    // 循环次数=0，声音会播放一次
    // 循环次数=1，声音会播放2次
    // 循环次数小于0，会无限循环播放
    [customSoundPlayer setNumberOfLoops:0];
    [customSoundPlayer setVolume:1.0];
    [customSoundPlayer prepareToPlay];
    [customSoundPlayer play];
}

- (void)stopReading {
    NSLog(@"stop reading");
    [self stopTimer];
    [_session stopRunning];
}

- (void)startReading {
    NSLog(@"start reading");
    [self createTimer];
    [_session startRunning];
}

//识别相册中图片二维码的点击函数，自己动手取图片吧
- (void)longPressClick:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan) return;
    UIImageView *tempImageView=(UIImageView*)sender.view;
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray* array =[detector featuresInImage:[CIImage imageWithCGImage:tempImageView.image.CGImage]];
    
    for (CIFeature* feature in array) {
        if([feature isKindOfClass:[CIQRCodeFeature class]]) {
            CIQRCodeFeature* QRCodeFeature = (CIQRCodeFeature*)feature;
            [[[UIAlertView alloc] initWithTitle:@"二维码" message:QRCodeFeature.messageString delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
            return;
        }
    }
    
    return ;
}

- (void)createTimer
{
    //创建一个时间计数
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(moveUpAndDownLine) userInfo:nil repeats:YES];
}

//二维码的横线移动
- (void)moveUpAndDownLine
{
    CGFloat Y = _QrCodeline.frame.origin.y;
    if (kMainScreenWidth - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop == Y){
        [UIView beginAnimations: @"asa" context:nil];
        [UIView setAnimationDuration:1];
        _QrCodeline.frame = CGRectMake(SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop, kMainScreenWidth - 2 * SCANVIEW_EdgeLeft, 1);
        [UIView commitAnimations];
    } else if (SCANVIEW_EdgeTop == Y){
        [UIView beginAnimations:@"asa" context:nil];
        [UIView setAnimationDuration:1];
        _QrCodeline.frame = CGRectMake(SCANVIEW_EdgeLeft, kMainScreenWidth - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop, kMainScreenWidth - 2 *SCANVIEW_EdgeLeft, 1);
        [UIView commitAnimations];
    }
}

- (void)stopTimer
{
    if ([_timer isValid] == YES) {
        [_timer invalidate];
        _timer = nil;
    }
}

-(void)openLight
{
    if (self.device.torchMode == AVCaptureTorchModeOff)
    {
        // Start session configuration
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        
        // Set torch to on
        [self.device setTorchMode:AVCaptureTorchModeOn];
        
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
        
        [openButton setTitle:@"关闭闪光灯" forState:UIControlStateNormal];
    }
    else
    {
        // Start session configuration
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        
        // Set torch to off4
        [self.device setTorchMode:AVCaptureTorchModeOff];
        
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
        
        [openButton setTitle:@"开启闪光灯" forState:UIControlStateNormal];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
