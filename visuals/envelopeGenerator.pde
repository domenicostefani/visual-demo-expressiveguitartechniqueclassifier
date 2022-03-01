
class PulseEnvelope {
  int attackMs = 100;
  int releaseMs = 500;
  
  private float envVal = 0.0;
  private boolean playing = false;
  private long timeOfStart = 0;
  
  PulseEnvelope () {}
  
  PulseEnvelope (int attack, int release) {
    super();
    this.attackMs = attack;
    this.releaseMs = release;
  }
  
  void loop() {
    if (playing) {
      long currentInterval = millis() - timeOfStart;
      if (currentInterval < attackMs) {
        // Attack phase
        envVal = currentInterval*1.0 / float (attackMs);
      } else if (currentInterval < attackMs + releaseMs) {
        // Release phase
        envVal = 1.0 - (currentInterval - attackMs)*1.0 / float (releaseMs);
      } else {
        playing = false;
      }
    }
  }
  
  void play() {
    playing = true;
    timeOfStart = millis();
  }
  
  void setAttackMs(int attackMs) {
    if (attackMs >= 0)
      this.attackMs = attackMs;
  }
  
  void setReleaseMs(int releaseMs) {
    if (releaseMs >= 0)
      this.releaseMs = releaseMs;
  }
  
  float getValue(){
    //assert(envVal <= 1.0);
    //assert(envVal >= 0.0);
    return envVal;
  }
}
