//
//  ViewController.m
//  CollisionPerformanceTestUIKit
//
//  Created by Yukinaga Azuma on 2015/01/04.
//  Copyright (c) 2015年 Yukinaga Azuma. All rights reserved.
//

#import "ViewController.h"
#import "Ball.h"

@interface ViewController ()
{
    int count;
    NSTimer *sTimer;
    NSMutableArray *ballArray;
    IBOutlet UILabel *countLabel;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    count = 0;
    sTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
                                              target:self
                                            selector:@selector(doAction)
                                            userInfo:nil
                                             repeats:YES];
    ballArray = [NSMutableArray new];
}

//タイマーから呼ばれるメソッド
-(void)doAction{
    
    //100個のボールが発生
    if (count < 200) {
        [self createBall];
        count++;
    }
    
    [self moveBall];
    [self collisionInArray:ballArray];
}

//ボールを生成
-(void)createBall{
    Ball *ball = [Ball new];
    ball.frame = CGRectMake(0, 0, 10, 10);
    ball.center = self.view.center;
    ball.backgroundColor = [UIColor orangeColor];
    ball.layer.cornerRadius = ball.frame.size.width/2.0;
    float speed = 1.0;
    float angle = (arc4random() % UINT32_MAX)*2*M_PI;
    float speedX = speed * cosf(angle);
    float speedY = speed * sinf(angle);
    ball.speed = CGVectorMake(speedX, speedY);
    [self.view addSubview:ball];
    [ballArray addObject:ball];
    
    //ボールをカウント
    countLabel.text = [NSString stringWithFormat:@"%d", [countLabel.text intValue]+1];
}

//ボールを動かす
-(void)moveBall{
    [ballArray enumerateObjectsUsingBlock:^(Ball *ball, NSUInteger idx, BOOL *stop) {
        
        //ボールの移動
        ball.center = CGPointMake(ball.center.x+ball.speed.dx,
                                  ball.center.y+ball.speed.dy);
        
        //端で反射
        if (ball.center.x<0) {
            ball.speed = CGVectorMake(fabsf(ball.speed.dx), ball.speed.dy);
        }
        if (ball.center.x>self.view.frame.size.width){
            ball.speed = CGVectorMake(-fabsf(ball.speed.dx), ball.speed.dy);
        }
        if (ball.center.y<0){
            ball.speed = CGVectorMake(ball.speed.dx, fabsf(ball.speed.dy));
        }
        if (ball.center.y>self.view.frame.size.height){
            ball.speed = CGVectorMake(ball.speed.dx, -fabsf(ball.speed.dy));
        }
    }];
}

//ボールの衝突
-(void)collisionInArray:(NSArray *)viewArray{
    [ballArray enumerateObjectsUsingBlock:^(Ball *view1, NSUInteger i, BOOL *stop1) {
        for (NSUInteger j=i+1; j<[ballArray count]; j++) {
            Ball *view2 = ballArray[j];
            
            //円形の判定は高コストなため、最初に矩形で判定
            float hitRadiusX = (view1.frame.size.width+view2.frame.size.width)/2.0;
            float hitRadiusY = (view1.frame.size.height+view2.frame.size.height)/2.0;
            float hitRadius = (hitRadiusX+hitRadiusY)/2.0;
            
            float distanceY =   view2.center.y - view1.center.y;
            if (fabsf(distanceY) > hitRadius) {
                continue;
            }
            
            float distanceX =  view2.center.x - view1.center.x;
            if (fabsf(distanceX) > hitRadius) {
                continue;
            }
            
            //円形で衝突判定
            float distance = sqrtf(distanceX*distanceX+ distanceY*distanceY);
            if (distance < hitRadius) {
                
                //衝突後のスピード計算
                CGVector unitVector;
                unitVector.dx = distanceX/distance;
                unitVector.dy = distanceY/distance;
                double e = 1.0;
                double speedFrom = view1.speed.dx*unitVector.dx+view1.speed.dy*unitVector.dy;
                double speedTo = view2.speed.dx*unitVector.dx+view2.speed.dy*unitVector.dy;
                double aN = 0.5*(1+e)*(speedTo-speedFrom);
                double dSx1 = aN*unitVector.dx;
                double dSy1 = aN*unitVector.dy;
                double dSx2 = -aN*unitVector.dx;
                double dSy2 = -aN*unitVector.dy;
                view1.speed = CGVectorMake(view1.speed.dx+dSx1, view1.speed.dy+dSy1);
                view2.speed = CGVectorMake(view2.speed.dx+dSx2, view2.speed.dy+dSy2);
                
                //2つのボールの重なりの解消
                float overlap = hitRadius-distance;
                float radius1 = (view1.frame.size.width+view1.frame.size.height)/2.0;
                float radius2 = (view2.frame.size.width+view2.frame.size.height)/2.0;
                float totalMass = radius1*radius1 + radius2*radius2;
                float move1 = overlap/totalMass*radius2*radius2;
                float move2 = overlap/totalMass*radius1*radius1;
                float cosign = distanceX/distance;
                float sign = distanceY/distance;
                float dx1 = -move1*cosign;
                float dy1 = -move1*sign;
                float dx2 = move2*cosign;
                float dy2 = move2*sign;
                view1.center = CGPointMake(view1.center.x+dx1, view1.center.y+dy1);
                view2.center = CGPointMake(view2.center.x+dx2, view2.center.y+dy2);
            }
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
