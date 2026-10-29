import processing.serial.*;
import java.util.ArrayList;

Serial port;
int portIndex = 2;

// Controls
int centerX = 2048, centerY = 2048, deadZone = 600;
boolean invertX = false, forwardIsLower = true;
float steering = 0;
boolean flying = false;
int previousReplayButton = -1;

// Player and cape
int playerSize = 220;
float playerX, pose = 0;
float sidewaysSpeed = 260;
float animationSpeed = 9, returnSpeed = 12;
int poseDirection = 1;

// Background and potentiometer
float scroll = 0;
float hoverSpeed = 35, flyingSpeed = 160;
float speed = hoverSpeed;
float daylight = 0, targetDaylight = 0;
boolean firstReading = true;

// Lights and timer
ArrayList<Light> lights = new ArrayList<Light>();
int score = 0;
float spawnDistance = 0;
float spacing = 230;
int duration = 60000;
int started, previousTime, lastSignal;

// Images
PImage[] skies = new PImage[3];
PImage[] views = new PImage[2];
PImage[] sprites = new PImage[6];
PImage[] digits = new PImage[10];
PImage lightImage, lightsLabel, timeLabel;

void setup() {
  size(800, 600);
  smooth();
  frameRate(60);

  String[] names = {"Day.png", "Sunset.png", "Night.png"};

  for (int i = 0; i < skies.length; i++) {
    skies[i] = asset(names[i]);
    skies[i].resize(width, 0);
  }

  for (int i = 0; i < views.length; i++) {
    views[i] = createImage(width, height, RGB);
  }

  for (int i = 0; i < sprites.length; i++) {
    sprites[i] = asset("sprite" + (i + 1) + ".png");
    sprites[i].resize(playerSize, 0);
    sprites[i].loadPixels();
  }

  lightImage = trimImage(asset("light.png"));
  lightImage.resize(64, 0);
  lightImage.loadPixels();

  PImage sheet = asset("ref sheet.png");
  lightsLabel = glyph(sheet, 410, 265, 710, 250);
  timeLabel = glyph(sheet, 410, 615, 670, 260);

  // Reference-sheet order: 1,2,3,4,5,6,7,8,9,0
  int[] edges = {
    130, 260, 450, 635, 820, 1000,
    1170, 1340, 1500, 1670, 1824
  };

  for (int i = 0; i < 10; i++) {
    digits[(i + 1) % 10] = glyph(
      sheet, edges[i], 940,
      edges[i + 1] - edges[i], 290
    );
  }

  String[] ports = Serial.list();
  printArray(ports);

  if (portIndex < 0 || portIndex >= ports.length) {
    throw new RuntimeException(
      "Choose a valid portIndex from the printed list."
    );
  }

  port = new Serial(this, ports[portIndex], 9600);
  port.clear();

  restartGame();
}

void draw() {
  // Read first because the replay button may reset the timer.
  readController();

  int now = millis();
  float dt = min((now - previousTime) / 1000.0, 0.1);
  previousTime = now;

  int remaining = max(0, duration - (now - started));
  boolean playing = remaining > 0;

  if (!playing || now - lastSignal > 500) {
    flying = false;
    steering = 0;
  }

  daylight = lerp(
    daylight, targetDaylight, 1 - exp(-5 * dt)
  );

  float travel = 0;

  if (playing) {
    playerX = constrain(
      playerX + steering * sidewaysSpeed * dt,
      playerSize / 2.0,
      width - playerSize / 2.0
    );

    updateCape(dt);

    speed = lerp(
      speed,
      flying ? flyingSpeed : hoverSpeed,
      1 - exp(-6 * dt)
    );

    travel = speed * dt;
    scroll = (scroll + travel) % skies[0].height;

    spawnDistance += travel;

    if (spawnDistance >= spacing) {
      spawnDistance -= spacing;
      lights.add(new Light(-70 - 2 * spacing));
    }
  }

  drawSky();

  PImage player = sprites[constrain(round(pose), 0, 5)];
  imageMode(CENTER);

  for (int i = lights.size() - 1; i >= 0; i--) {
    Light light = lights.get(i);

    if (playing) {
      light.y += travel;

      // Touching collects a light, even while hovering.
      if (touching(light, player)) {
        score++;
        lights.remove(i);
        continue;
      }

      if (light.y - lightImage.height / 2.0 > height) {
        lights.remove(i);
        continue;
      }
    }

    image(lightImage, light.x, light.y);
  }

  image(player, playerX, height / 2.0);

  drawHud(lightsLabel, str(score), 12, 300);
  drawHud(
    timeLabel,
    nf((remaining + 999) / 1000, 2),
    width - 250,
    238
  );

  if (!playing) {
    drawEnding();
  }
}

void restartGame() {
  score = 0;
  spawnDistance = 0;
  scroll = 0;
  speed = hoverSpeed;

  playerX = width / 2.0;
  pose = 0;
  poseDirection = 1;

  lights.clear();

  for (int i = 0; i < 3; i++) {
    lights.add(new Light(-70 - i * spacing));
  }

  started = previousTime = millis();

  // Keep the time of day selected by the knob.
}

void updateCape(float dt) {
  if (!flying) {
    pose = max(0, pose - returnSpeed * dt);
    poseDirection = 1;
    return;
  }

  pose += poseDirection * animationSpeed * dt;

  if (pose >= 5) {
    pose = 5;
    poseDirection = -1;
  } else if (pose <= 0) {
    pose = 0;
    poseDirection = 1;
  }
}

// Blend only the visible portions of the tall backgrounds.
void drawSky() {
  int first = daylight <= 0.5 ? 0 : 1;
  float blend = constrain(daylight * 2 - first, 0, 1);

  imageMode(CORNER);
  noTint();

  int base = blend > 0.995 ? first + 1 : first;

  copyView(skies[base], views[0]);
  image(views[0], 0, 0);

  if (blend >= 0.005 && blend <= 0.995) {
    copyView(skies[first + 1], views[1]);
    tint(255, blend * 255);
    image(views[1], 0, 0);
    noTint();
  }
}

void copyView(PImage source, PImage view) {
  int sourceY = (
    source.height - round(scroll) % source.height
  ) % source.height;

  int destinationY = 0;

  while (destinationY < height) {
    int rows = min(
      source.height - sourceY,
      height - destinationY
    );

    view.copy(
      source, 0, sourceY, width, rows,
      0, destinationY, width, rows
    );

    destinationY += rows;
    sourceY = 0;
  }
}

class Light {
  float x = random(110, width - 110);
  float y;

  Light(float y) {
    this.y = y;
  }
}

// Check visible pixels, ignoring transparent margins.
boolean touching(Light light, PImage player) {
  float px = playerX - player.width / 2.0;
  float py = height / 2.0 - player.height / 2.0;
  float lx = light.x - lightImage.width / 2.0;
  float ly = light.y - lightImage.height / 2.0;

  int left = int(ceil(max(px, lx)));
  int right = int(floor(min(
    px + player.width,
    lx + lightImage.width
  )));

  int top = int(ceil(max(py, ly)));
  int bottom = int(floor(min(
    py + player.height,
    ly + lightImage.height
  )));

  for (int y = top; y < bottom; y++) {
    int playerRow = int(y - py) * player.width;
    int lightRow = int(y - ly) * lightImage.width;

    for (int x = left; x < right; x++) {
      int a = player.pixels[
        playerRow + int(x - px)
      ] >>> 24;

      int b = lightImage.pixels[
        lightRow + int(x - lx)
      ] >>> 24;

      if (a > 40 && b > 40) {
        return true;
      }
    }
  }

  return false;
}

void drawHud(
  PImage label, String number,
  float x, float panelWidth
) {
  imageMode(CORNER);
  noStroke();

  fill(15, 48, 80, 160);
  rect(x, 12, panelWidth, 58, 12);

  image(label, x + 12, 24);
  x += 12 + label.width + 14;

  for (int i = 0; i < number.length(); i++) {
    PImage digit = digits[number.charAt(i) - '0'];
    image(digit, x, 24);
    x += digit.width + 4;
  }
}

void drawEnding() {
  fill(15, 48, 80, 220);
  rect(
    width / 2.0 - 200,
    height / 2.0 - 85,
    400, 170, 18
  );

  fill(255, 235, 225);
  textAlign(CENTER, CENTER);

  textSize(32);
  text(
    "Time's up!",
    width / 2.0, height / 2.0 - 40
  );

  textSize(22);
  text(
    "Lights collected: " + score,
    width / 2.0, height / 2.0
  );

  textSize(17);
  text(
    "Press the button to play again",
    width / 2.0, height / 2.0 + 42
  );
}

PImage asset(String filename) {
  PImage img = loadImage(filename);

  if (img == null) {
    throw new RuntimeException("Missing data/" + filename);
  }

  return img;
}

// Extract and resize handwriting once during setup.
PImage glyph(
  PImage sheet,
  int x, int y, int w, int h
) {
  float sx = sheet.width / 1824.0;
  float sy = sheet.height / 1368.0;

  PImage img = trimImage(sheet.get(
    round(x * sx), round(y * sy),
    round(w * sx), round(h * sy)
  ));

  img.resize(0, 34);
  return img;
}

PImage trimImage(PImage img) {
  img.loadPixels();

  int left = img.width, right = -1;
  int top = img.height, bottom = -1;

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      if ((img.pixels[y * img.width + x] >>> 24) > 20) {
        left = min(left, x);
        right = max(right, x);
        top = min(top, y);
        bottom = max(bottom, y);
      }
    }
  }

  return right < left ? img : img.get(
    left, top,
    right - left + 1,
    bottom - top + 1
  );
}

float horizontalAxis(int x) {
  if (x < centerX - deadZone) {
    return map(x, 0, centerX - deadZone, -1, 0);
  }

  if (x > centerX + deadZone) {
    return map(x, centerX + deadZone, 4095, 0, 1);
  }

  return 0;
}

void readController() {
  // After a connection gap, establish the button state again.
  if (millis() - lastSignal > 500) {
    previousReplayButton = -1;
  }

  while (port.available() > 0) {
    String line = port.readStringUntil('\n');
    if (line == null) break;

    String[] values = split(trim(line), ',');
    if (values.length != 5) continue;

    try {
      int x = Integer.parseInt(trim(values[0]));
      int y = Integer.parseInt(trim(values[1]));
      // values[2] is the unused joystick click switch.
      int pot = Integer.parseInt(trim(values[3]));
      int button = Integer.parseInt(trim(values[4]));

      if (x < 0 || x > 4095 ||
          y < 0 || y > 4095 ||
          pot < 0 || pot > 4095 ||
          (button != 0 && button != 1)) {
        continue;
      }

      targetDaylight = pot / 4095.0;

      if (firstReading) {
        daylight = targetDaylight;
        firstReading = false;
      }

      steering = horizontalAxis(x) * (invertX ? -1 : 1);

      boolean forward = forwardIsLower
        ? y < centerY - deadZone
        : y > centerY + deadZone;

      if (forward && !flying) {
        poseDirection = 1;
      }

      flying = forward;
      lastSignal = millis();

      boolean newPress =
        previousReplayButton == 1 && button == 0;

      if (newPress) {
        restartGame();
      }

      previousReplayButton = button;
    }
    catch (NumberFormatException e) {
      // Ignore malformed serial messages.
    }
  }
}