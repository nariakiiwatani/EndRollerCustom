// Copyright (c) 2015 nariakiiwatani
// Released under the MIT license
// http://opensource.org/licenses/mit-license.php

/* @pjs font="ikamodoki1_0.ttf"; */
/* @pjs preload="images/header.png"; */

float wrap(float value, float min, float max) {
  if(min >max) {
    float tmp = min; min = max; max = tmp;
  }
  while(value < min) {
    value += max-min;
  }
  while(value > max) {
    value -= max-min;
  }
  return value;
}


class Particle
{
  float mass_ = 30;
  PVector pos_ = new PVector();
  PVector vel_ = new PVector();
  PVector acc_ = new PVector();
  float air_damping_ = 0.01;
  float wall_damping_ = 0.99;
  boolean is_on_wall_ = false;
  color color_;
  float size_ = 30;
  float draw_size_ = 25;
  Particle() {
    float random_factor = random(0.8,1.2);
    mass_ *= random_factor;
    size_ *= random_factor;
    draw_size_ *= random_factor;
  }
  void setPos(PVector pos) { pos_.set(pos); }
  void setVel(PVector vel) { vel_.set(vel); }
  void addForce(PVector force) { 
    force.div(mass_);
    acc_.add(force);
  }
  void update() {
    vel_.add(acc_);
    vel_.mult(1 - (is_on_wall_ ? wall_damping_ : air_damping_));
    pos_.add(vel_);
    if(isOnWall()) {
      pos_.y -= scroll_speed_;
    }
  }
  void clearForce() { acc_.set(0, 0, 0); }
  void draw(PGraphics target) {
    target.pushStyle();
    target.noStroke();
    target.fill(color_);
    target.pushMatrix();
    target.translate(pos_.x, pos_.y, pos_.z);
//    target.scale(map(pow((200-pos_.z)/200,0.5), 0, 1, 1, 2));
    target.ellipse(0, 0, draw_size_*2, draw_size_*2);
    target.popMatrix();
    target.popStyle();
  }
  void setOnWall(boolean on) {
    is_on_wall_ = on;
    vel_.x = vel_.z = 0;
  }
  boolean isOnWall() { return is_on_wall_; }
  void setColor(color c) { color_ = c; }
  PVector getPos() { return pos_; }
  PVector getVel() { return vel_; }
  float getHitSize() { return size_; }
  float getDrawSize() { return draw_size_; }
  float getMass() { return mass_; }
  void shrink(float rate) {
    draw_size_ *= 1-rate;
    mass_ *= 1-rate;
  }
};

ArrayList<Particle> particles_ = new ArrayList();
float gravity_ = 120;
float wall_pos_ = 0;
float wall_cefficient_ = 0.5;
PVector pos_width_ = new PVector(0,0,100);
PVector vel_center_ = new PVector(0,-100,-250);
PVector vel_width_ = new PVector(50,50,100);
float shoot_num_ = 10;
float shoot_interval_ = 0.06;
float shoot_interval_timer_ = 0;
boolean is_shooting_ = false;
int shoot_color_index_ = 0;
float shoot_pos_ = 200;
PGraphics fixed_, scrolled_, eraser_;
PImage header_, footer_;
String article_;

//--------------------------------------------------------------
void setup(){
  size(720, 405, P2D);
  background(0);
  frameRate(30);
  ellipseMode(RADIUS);
  colorMode(HSB, 1);
  eraser_ = createGraphics(width, 32, P2D);
  fixed_ = createGraphics(width, height*2, P2D);
  scrolled_ = createGraphics(width, fixed_.height+eraser_.height, P2D);
  eraser_.beginDraw();
  eraser_.background(0);
  eraser_.endDraw();
  textFont(createFont("ikamodoki1_0.ttf", 48));
  textAlign(CENTER, TOP);

  header_ = loadImage("images/header.png");
  footer_ = loadImage("images/footer.png");
  article_ = ["",
  "スプラトゥーンのあれを",
  "ツクってみました。",
  "ホンケとはインクのかんじが",
  "だいぶチガいますが",
  "とりあえずバージョン1ということで・・・",
  "",
  "いろいろイイワケは",
  "ありますケド",
  "とりあえずたのしいモノには",
  "なったかなと",
  "オモいますので",
  "コウカイしてみます。",
  "",
  "イヨクシダイで",
  "アップデートします。",
  "（コメントもらえるとやるキがでます）",
  "",
  "サイショとサイゴのガゾウと",
  "ナカのテキストは",
  "ヘンコウできるので",
  "スキにツカってください。",
  "",
  "タトえばニコニコでジッキョウの",
  "アトガタリにとか",
  "ツカってもらえたら",
  "メチャめちゃウレしいです。",
  "",
  "そのホカ、",
  "シヨウにあたって",
  "トクにセイゲンは",
  "もうけていませんが",
  "フォントはトツカコダマさんの",
  "イカモドキをツカわせて",
  "いただいていますので",
  "そちらのキヤクも",
  "マモってくださいね。",
  "",
  "こんごのアップデートは",
  "ミテイですが",
  "インクのクオリティアップとか",
  "クイックボムのジッソウとか",
  "ガゾウかきだしとか",
  "ドウガかきだしとか",
  "コウソクカとか",
  "スマホタイオウとか",
  "いろいろカンガえてはいます",
  "",
  "それでは",
  "イツになるか",
  "わかりませんが",
  "ツギのアップデートを",
  "オタノシミに・・・",
  "",
  "イカ、よろしく〜！",
  "",
  ""].join('\n');

  startApplet();
}

void clearFbo(PGraphics dst) {
  dst.beginDraw();
  dst.background(0,0);
  dst.endDraw();
}

//--------------------------------------------------------------
void update(){
  if (is_shooting_) {
    shoot_interval_timer_ += 1/frameRate;
    if (shoot_interval_timer_ >= shoot_interval_) {
      shoot(mouseX, mouseY);
      shoot_interval_timer_ = 0;
    }
  }
  fixed_.beginDraw();
  for(int i = particles_.size()-1; i >= 0; i--) { 
    Particle p = particles_.get(i);
    p.addForce(new PVector(0, gravity_*p.getMass(), 0));
    p.update();
    p.clearForce();
    if (isOnWall(p)) {
      p.setOnWall(true);
      p.shrink(0.06*30/frameRate);
      p.draw(fixed_);
    }
    else if (isHitWall(p)) {
      PVector v = p.getVel();
      v.x *= wall_cefficient_;
      v.y *= wall_cefficient_;
      v.z *= -wall_cefficient_;
      p.setVel(v);
      p.shrink(0.8);
    }
    if (isOutOfBounds(p) || (p.getDrawSize() < 5)) {
      p.draw(fixed_);
      particles_.remove(i);
    }
  }
  fixed_.endDraw();

  scroll_amount_ += scroll_speed_;
  if(scroll_amount_ >= article_ends_at_) {
    endScroll();
  }
}

boolean isOnWall(Particle p) {
  return abs(p.getPos().z-wall_pos_) < p.getHitSize();
}
boolean isHitWall(Particle p) {
  if (p.getVel().z > 0) {
    return wall_pos_ - p.getPos().z < p.getHitSize();
  }
  else if(p.getVel().z < 0) {
    return p.getPos().z - wall_pos_ < p.getHitSize();
  }
  else {
    return isOnWall(p);
  }
}
boolean isOutOfBounds(Particle p) {
  return p.getPos().y - p.getHitSize() > height;
}

void drawYScrolledImage(PGraphics dst, PGraphics src, float shift) {
  dst.beginDraw();
  if(src.height <= dst.height) {
    shift = wrap(shift, 0, dst.height);
    dst.image(src,0,shift);
    if(shift+src.height > dst.height) {
      dst.image(src,0,shift-dst.height);
    }
  }
  else {
    shift = wrap(shift, 0, src.height);
    dst.image(src, 0, shift-src.height);
    if(shift < dst.height) {
      dst.image(src, 0, shift);
    }
  }
  dst.endDraw();
}

//--------------------------------------------------------------
void draw(){
  clearFbo(fixed_);
  update();
  background(0);

  drawYScrolledImage(scrolled_, eraser_, scroll_amount_-eraser_.height-1);
  drawYScrolledImage(scrolled_, fixed_, scroll_amount_);
  drawYScrolledImage(this, scrolled_, -scroll_amount_);

  float header_height = header_.height*width/header_.width;
  article_ends_at_ = line_height_*(split(article_, '\n').length+1)+header_height+height;

  pushMatrix();
  translate(0, -scroll_amount_);
  if(scroll_amount_ < header_height) {
    image(header_, 0, 0, width, header_height);
  }
  translate(0, header_height);
  if(0 < scroll_amount_ && scroll_amount_ < article_ends_at_) {
    pushStyle();
    noStroke();
    fill(0);
    text(article_,width/2,0,width);
    popStyle();
  }
  translate(0, article_ends_at_-header_height);
  if(scroll_amount_ >= article_ends_at_-header_height) {
    image(footer_, 0, 0, width, width*footer_.height/footer_.width);
  }
  popMatrix();

  for(int i = particles_.size()-1; i >= 0; i--) { 
    particles_.get(i).draw(this);
  }
  pushMatrix();
  translate(mouseX, mouseY);
  pushStyle();
  noFill();
  stroke(0,0,1);
  ellipse(0, 0, 10, 10);
  ellipse(0, 0, 8, 8);
  line(0, -15, 0, 15);
  line(-15, 0, 15, 0);
  if (is_shooting_) {
    color c = color(shoot_color_index_*0.33f, 1, 1);
    stroke(c);
  }
  ellipse(0, 0, 9, 9);
  popStyle();
  popMatrix();
}

//--------------------------------------------------------------
void keyPressed(){
  switch (key) {
  case 'c':
    clearInk();
    break;
  case ' ':
  if(!is_shooting_) {
      is_shooting_ = true;
      shoot_interval_timer_ = 0;
      shoot(mouseX,mouseY);
    }
    break;
  }
}
void clearInk() {
  clearFbo(fixed_);
  clearFbo(scrolled_);
  particles_.clear();
}
//--------------------------------------------------------------
void keyReleased(){
  is_shooting_ = false;
}

//--------------------------------------------------------------
void mousePressed(){
  if(++shoot_color_index_ > 2) {
    shoot_color_index_ = 0;
  }
  shoot(mouseX,mouseY);
}

void shoot(float x, float y){
  color c = color(shoot_color_index_*0.33f, 1, 1, 0.99);
  for (int i = 0; i < shoot_num_; ++i) {
    int random_count = 4;
    PVector pos_factor = new PVector(0, 0, 0);
    PVector vel_factor = new PVector(0, 0, 0);
    for (int r = 0; r < random_count; ++r) {
      pos_factor.x += random(-1, 1);
      pos_factor.y += random(-1, 1);
      pos_factor.z += random(-1, 1);
      vel_factor.x += random(-1, 1);
      vel_factor.y += random(-1, 1);
      vel_factor.z += random(-1, 1);
    }
    pos_factor.div(random_count);
    vel_factor.div(random_count);
    PVector pos = new PVector(x, y, shoot_pos_);
    pos.add(pos_width_.x*pos_factor.x, pos_width_.y*pos_factor.y, pos_width_.z*pos_factor.z);
    PVector vel = new PVector(vel_center_.x, vel_center_.y, vel_center_.z);
    vel.add(vel_width_.x*vel_factor.x, vel_width_.y*vel_factor.y, vel_width_.z*vel_factor.z);
    oneShot(pos, vel, c);
  }
}

void oneShot(PVector pos, PVector vel, color c) {
  Particle p = new Particle();
  p.setColor(c);
  p.setPos(pos);
  p.setVel(vel);
  particles_.add(p);
}

//----- talking with js -----
float scroll_speed_ = 0;
float scroll_amount_ = 0;
float line_height_ = 64;
float article_ends_at_ = 99999;
void loadHeader(String url) {
  header_ = loadImage(url);
}
void loadFooter(String url) {
  footer_ = loadImage(url);
}
void setArticle(String article) {
  article_ = article;
}
void startApplet() {
  scroll_amount_ = 0;
  setTimeout(function() { startScroll(0.7); }, 10000);
}
void startScroll(float speed) {
  scroll_speed_ = speed;
}
void endScroll() {
  scroll_speed_ = 0;
}
