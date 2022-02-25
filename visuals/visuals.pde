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

// Do not modify following classes/ variables!
AudioInput audioIn;
BeatDetect beat;  
MidiBus midi1;
Minim minim;
FFT fft;
boolean amplitudeMultiplier;
boolean autoChangeColor;
int numberOfCircles = 1;
float smoothFactor = 1;
float increaseRotate;
float multiplier = 3;
float increaser = 0;
float alpha = 255;
float color_h2 = 255;
float color_s2 = 255;
float color_v2 = 255;
float smoother;
float rotator;
float color_h;
float color_s;
float color_v;
float amp;

boolean USE_FFT = false;
//_______________________________________________________________________________________________________________________________
void setup() {
  colorMode(HSB, 360);
  fullScreen(OPENGL); // Sketch will always be fullscreen
  midi1 = new MidiBus(this, deviceNameOne, deviceNameOne); // Initialize the MIDI devices..
  minim = new Minim(this); // Create a new Minim class for sound input
  audioIn = minim.getLineIn(Minim.STEREO);  // Get the system audio
  if(USE_FFT)
    fft = new FFT(audioIn.bufferSize(), audioIn.sampleRate()); // Create a new FFT class for Fast Fourier Transformation
  beat = new BeatDetect();
  strokeWeight(4);
  rectMode(CENTER);
  
  //MidiBus.list();
}

//_______________________________________________________________________________________________________________________________
void draw () {
  background(color_h, color_s, color_v, 50); // Reset the background for every loop
  //beatDetection();
  audioVisualizer();
}

//_______________________________________________________________________________________________________________________________

//_______________________________________________________________________________________________________________________________
void audioVisualizer() {
  if(USE_FFT)
    fft.forward(audioIn.mix); // Execute a FFT on the increaseroming audio
  amp = 1;
  stroke(color_h2, color_s2, color_v2, alpha); 
  translate(width/2, height/2); // Get the middle point to rotate around
  for (int size = int(100*multiplier); size <= int(100*multiplier+(10*numberOfCircles)); size += borderAroundCircles) {
    for (int deg = 0; deg <= 360; deg++) { // Draw two full reacting circles 
      pushMatrix();
      if(USE_FFT)
          smoother +=  ((fft.getBand(deg+20)/100 - smoother) * smoothFactor); // Smooth out the frequenty amplitude
      else
          smoother +=  ((3/100 - smoother) * smoothFactor); // Smooth out the frequenty amplitude
      float Cx = size*cos(radians(deg+90+increaser*(map(size, 150, 250, -1, 2)))) * amp * (1 + smoother);
      float Cy = size*sin(radians(deg+90+increaser*(map(size, 150, 250, -2, 2)))) * amp * (1 + smoother); 
      
      //println(increaser);
      
      
      color_h = map(sin(increaser),-1,+1,0,360);
      //color_s = map(increaser+offset_g % 20,offset_g,20+offset_g,0,255);
      //color_v = map(increaser % 20,0,20,0,255);
      translate(0, 0, smoother*200);
      point(Cx, Cy);
      point(-Cx, Cy);
      popMatrix();
    }
  }
  increaser = increaser + rotator;
}

//_______________________________________________________________________________________________________________________________
void controllerChange(int channel, int controlNumber, int value) { // Get incoming MIDI messages and map them to variables
  //println("Control:",controlNumber);
  //if (controlNumber == 120) { // If turning knob 0, change the alpha value of the audio visualizer
  //  alpha = map(value, 0, 127, 0, 255);
  //}
  //if (controlNumber == 121) {
  //  color_h = int(map(value, 0, 127, 0, 255));
  //}else if (controlNumber == 122) {
  //  color_s = int(map(value, 0, 127, 0, 255));
  //}else if (controlNumber == 123) {
  //  color_v = int(map(value, 0, 127, 0, 255));
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
  //  color_h2 = random(255);
  //  color_s2 = random(255);
  //  color_v2 = random(255);
  //}
  //if (pitch == 15) { // If selected, change background color automatically
  //  color_h = random(255);
  //  color_s = random(255);
  //  color_v = random(255);
  //}
}

//_______________________________________________________________________________________________________________________________
void keyPressed() {
  if (key == 's' || key == 'S') {
    smoothFactor = 0.01;
    numberOfCircles = 10;
    rotator = 0.2;
  }  
}
