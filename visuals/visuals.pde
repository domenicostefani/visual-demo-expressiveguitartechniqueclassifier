// This Audio Visualizer works together with MIDI device which outputs CC MIDI messages on channel 0 and controller number 0 - 4. 

//Short description_______________________________________________________________________________________________________________________________
// This deliverable for the academic study ‘Creative Programming’ shows an Audio Visualizer which feeds on the internal sound flowing
// through your computer! Various settings can be changed by the Arduino MIDI controller or literally any other device capable of sending
// MIDI messages (See the Maschine MK2 drum controller in the video). If you do not have access of a MIDI device, hit the ’s’ key to get
// a preview of the possibilities of the Audio Visualizer. 

//How it works____________________________________________________________________________________________________________________________________
// Processing uses the Minim library to analyse the incoming audio for amplitude, spectrum frequencies and beat detection. Certain parameters 
// are linked to these analyses to make the sound appear visually on your screen. With the Arduino (or other MIDI devices) it is possible to 
// change certain parameters to make the Audio Visualizer more appealing.

//Requirements to run the Audio Visualizer_________________________________________________________________________________________________________
//- Processing 3.0
//- Internal audio routing possibilities (I used SoundFlower for OS X)
//- For best performance, play a song with a noticeable bass drum.

// © Copyright by Bas van Straaten
// https://github.com/basboy12/Processing_audio_visualizer

// Import some necessary library's
import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.signals.*;

import themidibus.*;  // MIDI
import oscP5.*;  // OSC


// Modify to your needs
String deviceNameOne = "Mini [hw:1,0,0]"; // find your MIDI device using MidiBus.list() in the setu
//String deviceNameOne = "Mini [hw:1,0,1]"; // find your MIDI device using MidiBus.list() in the setu
//String deviceNameOne = "Mini [hw:1,0,2]"; // find your MIDI device using MidiBus.list() in the setu
//String deviceNameOne = "Mini [hw:1,0,3]"; // find your MIDI device using MidiBus.list() in the setu
float borderAroundCircles = 25;
float boxSize = 4;


AudioInput audioIn;
BeatDetect beat;  
MidiBus midi1;
Minim minim;
FFT fft;
boolean amplitudeMultiplier;
boolean autoChangeColor;

float MAX_HSV_ANGLE = 360;
 //<>//


class Visualizer {
  // Circle Color
  float colorH = 255;
  float colorS = 100;
  float colorV = MAX_HSV_ANGLE;
  float colorA = 300;
  // Size and number
  int numberOfCircles = 1;
  int circleSize = 100;
  float smoothFactor = 1;
  
  private float increaser = 0;
  private float smoother;
  private float rotator;

  void draw() {
    if(USE_FFT)
      fft.forward(audioIn.mix); // Execute a FFT on the increaseroming audio
    amp = 1;
    stroke(this.colorH, this.colorS, this.colorV, this.colorA); 
    translate(width/2, height/2); // Get the middle point to rotate around
    for (int size = circleSize; size <= int(circleSize+(10*numberOfCircles)); size += borderAroundCircles) {
      for (int deg = 0; deg <= MAX_HSV_ANGLE; deg++) { // Draw two full reacting circles 
        pushMatrix();
        if(USE_FFT)
            smoother +=  ((fft.getBand(deg+20)/100 - smoother) * smoothFactor); // Smooth out the frequenty amplitude
        else
            smoother +=  ((3/100 - smoother) * smoothFactor); // Smooth out the frequenty amplitude
        float Cx = size*cos(radians(deg+90+increaser*(map(size, 150, 250, -1, 2)))) * amp * (1 + smoother);
        float Cy = size*sin(radians(deg+90+increaser*(map(size, 150, 250, -2, 2)))) * amp * (1 + smoother); 
        
        translate(0, 0, smoother*200);
        point(Cx, Cy);
        point(-Cx, Cy);
        popMatrix();
      }
    }
    increaser += rotator;
  }
  
  void setRotator(float rotator) {
    this.rotator = rotator;
  }
}

class BackgroundColor {
  boolean autocolor = false;
  float backgroundColorH = MAX_HSV_ANGLE;
  float backgroundColorS = 200;
  float backgroundColorV = 0;
  
  int refreshPeriodms = 10;
  int lastRefresh;
  
  
  BackgroundColor() { this.lastRefresh = millis(); }
  
  BackgroundColor(int backgroundColorH, int backgroundColorS, int backgroundColorV)
  {
    super();
    this.backgroundColorH = backgroundColorH;
    this.backgroundColorS = backgroundColorS;
    this.backgroundColorV = backgroundColorV;
    this.refreshPeriodms = refreshPeriodms;
  }
  
  BackgroundColor(int backgroundColorH, int backgroundColorS, int backgroundColorV,int refreshPeriodms)
  {
    super(); // TODO: check why I can't use super(int,int,int) even if if is defined above
    this.backgroundColorH = backgroundColorH;
    this.backgroundColorS = backgroundColorS;
    this.backgroundColorV = backgroundColorV;
    this.refreshPeriodms = refreshPeriodms;
  }
  
  void draw()
  {
    if(this.autocolor && millis() - this.lastRefresh > this.refreshPeriodms)
    {
      backgroundColorH = (backgroundColorH + 1)%MAX_HSV_ANGLE;
      //backgroundColorS = map(increaser+offset_g % 20,offset_g,20+offset_g,0,255);
      //backgroundColorV = map(increaser % 20,0,20,0,255);
      this.lastRefresh = millis();
    }
    background(backgroundColorH, backgroundColorS, backgroundColorV);
  }
  
  void setColorH(float colorH){
    if (colorH >= 0 && colorH <= MAX_HSV_ANGLE)
      this.backgroundColorH = colorH;
  }
  
  void setColorS(float colorS){
    if (colorS >= 0 && colorS <= MAX_HSV_ANGLE)
      this.backgroundColorS = colorS;
  }
  
  void setColorV(float colorV){
    if (colorV >= 0 && colorV <= MAX_HSV_ANGLE)
      this.backgroundColorV = colorV;
  }
}

Visualizer visualizer;
BackgroundColor backcolor;
PulseEnvelope env;
OscP5 osc;

Float prediction_threshold = null; // TODO change here to rule out some predictions based on the softmax out value


float amp;

boolean USE_FFT = false;
boolean USE_MIDI = false;
int default_circle_size = 0;
//_______________________________________________________________________________________________________________________________
void setup() {
  colorMode(HSB, MAX_HSV_ANGLE);
  //size(640, 400);
  fullScreen(OPENGL); // Sketch will always be fullscreen
  
  visualizer = new Visualizer();
  int smallerSide = height < width ? height : width;
  int borderAroundCircle = int(1.0/8.0 * smallerSide);
  default_circle_size = smallerSide/2 - borderAroundCircle;
  visualizer.circleSize = default_circle_size;
  
  backcolor = new BackgroundColor();
  
  if (USE_MIDI)
  {
    midi1 = new MidiBus(this, deviceNameOne, deviceNameOne); // Initialize the MIDI devices..
    //MidiBus.list();
  }
    
  minim = new Minim(this); // Create a new Minim class for sound input
  audioIn = minim.getLineIn(Minim.STEREO);  // Get the system audio
  if(USE_FFT)
    fft = new FFT(audioIn.bufferSize(), audioIn.sampleRate()); // Create a new FFT class for Fast Fourier Transformation
  beat = new BeatDetect();
  strokeWeight(4);
  rectMode(CENTER);
  
  osc = new OscP5(this, 9001);
  
  env = new PulseEnvelope();
  
  
  visualizer.smoothFactor = 0.01;
  visualizer.numberOfCircles = 10;
  visualizer.rotator = 0.2;
}

float currentHue = 0;
void draw () {  
  env.loop();
  
  float envval = env.getValue();
  backcolor.setColorV(50 + 200*envval);
  visualizer.setRotator(0.3 + 0.2*envval);
  //visualizer.circleSize = int(default_circle_size + (30.0*envval));
  //println(env.getValue());
  
  backcolor.draw();
  visualizer.draw();
}


//_______________________________________________________________________________________________________________________________
void keyPressed() {
  if (key == 's' || key == 'S') {
    visualizer.smoothFactor = 1;
    visualizer.numberOfCircles = 10;
    visualizer.rotator = 0.2;
  }  
}

void predictedClass(int prediction) {
  println("predicted class",prediction); //<>//
  float colors = 360.0 * prediction / 8.0;
  backcolor.setColorH(colors);
  env.play();
}

/**
 *  Receive and handle OSC messages that describe the class of expressive guitar technique predicted
 *  Types of messages, depending on classifier configuration:
 *   a. "/guitarClassifier/class" message with 8 float values, indicating the 8 outputs of the last softmax layer of the neural network (some kind of confidence values)
 *   b. "/guitarClassifier/class" message with 1 int value, indicating the predicted class
 *   c. "/guitarClassifier/class" message with 1 int value, indicating the predicted class, and 1 float value containing the corresponding softmax output value
 */
void oscEvent(OscMessage theOscMessage) {
  println("Received OSC: "+theOscMessage+" - ");
  if (theOscMessage.checkAddrPattern("/guitarClassifier/class")==true) {
    if (theOscMessage.checkTypetag("ffffffff")) {  // (a) softmax output
      float[] softmaxOut = new float[8];
      for (int i=0;i<8;++i)
        softmaxOut[i] = theOscMessage.get(i).floatValue();
      // Argmax
      int maxclass = 0;
      for (int i=0;i<8;++i)
        if (softmaxOut[i] > softmaxOut[maxclass])
          maxclass = i;
      // Threshold
      if (prediction_threshold == null || softmaxOut[maxclass] > prediction_threshold)
        predictedClass(maxclass);
    } 
    else if (theOscMessage.checkTypetag("i"))      // (b) Class value [1-8]
    {
      predictedClass(theOscMessage.get(0).intValue());        //<>//
    } 
    else if (theOscMessage.checkTypetag("if"))     // (c) Class and output of softmax for that class
    { 
      // Threshold
      if (prediction_threshold == null || theOscMessage.get(1).floatValue() > prediction_threshold)
        predictedClass(theOscMessage.get(0).intValue());    
    }
  }
}
