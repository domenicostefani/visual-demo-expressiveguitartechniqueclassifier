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
import themidibus.*;

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



class Visualizer {
  // Circle Color
  float colorH = 255;
  float colorS = 100;
  float colorV = MAX_HSV_ANGLE;
  float colorA = 100;
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
}

class BackgroundColor {
  float backgroundColorH = MAX_HSV_ANGLE;
  float backgroundColorS = 100;
  float backgroundColorV = 200;
  
  int refreshPeriodms = 10;
  int time;
  
  
  BackgroundColor()
  {
    this.time = millis();
  }
  
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
    if(millis() - this.time > this.refreshPeriodms)
    {
      backgroundColorH = (backgroundColorH + 1)%MAX_HSV_ANGLE;
      //backgroundColorS = map(increaser+offset_g % 20,offset_g,20+offset_g,0,255);
      //backgroundColorV = map(increaser % 20,0,20,0,255);
      this.time = millis();
    }
    background(backgroundColorH, backgroundColorS, backgroundColorV, 50);
  }
}

Visualizer visualizer;
BackgroundColor backcolor;


float amp;

boolean USE_FFT = false;
boolean USE_MIDI = false;

//_______________________________________________________________________________________________________________________________
void setup() {
  colorMode(HSB, MAX_HSV_ANGLE);
  size(640, 400);
  //fullScreen(OPENGL); // Sketch will always be fullscreen
  
  
  
  visualizer = new Visualizer();
  int smallerSide = height < width ? height : width;
  int borderAroundCircle = int(1.0/8.0 * smallerSide);
  visualizer.circleSize = smallerSide/2 - borderAroundCircle;
  
  backcolor = new BackgroundColor(0,200,200,10);
  
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
  
  

}


//_______________________________________________________________________________________________________________________________
void draw () {
  //beatDetection();
  backcolor.draw();
  visualizer.draw();
}


//_______________________________________________________________________________________________________________________________
void controllerChange(int channel, int controlNumber, int value) { // Get incoming MIDI messages and map them to variables
  //println("Control:",controlNumber);
  //if (controlNumber == 120) { // If turning knob 0, change the circleColorA value of the audio visualizer
  //  circleColorA = map(value, 0, 127, 0, 255);
  //}
  //if (controlNumber == 121) {
  //  backgroundColorH = int(map(value, 0, 127, 0, 255));
  //}else if (controlNumber == 122) {
  //  backgroundColorS = int(map(value, 0, 127, 0, 255));
  //}else if (controlNumber == 123) {
  //  backgroundColorV = int(map(value, 0, 127, 0, 255));
  //}

}

//_______________________________________________________________________________________________________________________________
void noteOn(int channel, int pitch, int volume) { // Get incoming MIDI messages and map them to variables
  println("Note:",pitch);

  //if (pitch == 12) { // If selected, change background color automatically
  //  if (autoChangeColor) {
  //    autoChangeColor = false;
  //  } else {
  //    autoChangeColor =true;
  //  }
  //}
  //if (pitch == 13) {
  //  if (amplitudeMultiplier) {
  //    amplitudeMultiplier = false;
  //  } else {
  //    amplitudeMultiplier =true;
  //  }
  //}
  //if (pitch == 14) { // If selected, change color of audio visualizer
  //  circleColorH = random(255);
  //  circleColorS = random(255);
  //  circleColorV = random(255);
  //}
  //if (pitch == 15) { // If selected, change background color automatically
  //  backgroundColorH = random(255);
  //  backgroundColorS = random(255);
  //  backgroundColorV = random(255);
  //}
}

//_______________________________________________________________________________________________________________________________
void keyPressed() {
  if (key == 's' || key == 'S') {
    visualizer.smoothFactor = 0.01;
    visualizer.numberOfCircles = 10;
    visualizer.rotator = 0.2;
  }  
}
