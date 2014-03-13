import 'package:angular/angular.dart';
import 'package:angular/animate/module.dart';

import 'dart:html';
import 'dart:math';

main() {
  ngBootstrap(module: new Module()
    ..install(new NgAnimateModule())
    ..type(AppController)
    ..type(BoxDirective));
}

@NgController(
  selector: '[app]',
  publishAs: 'appCtrl'
)
class AppController {
  Mouse mouse = new Mouse();

  mouseMove(MouseEvent event) {
    mouse.x = event.client.x;
    mouse.y = event.client.y;
  }
}

class Mouse {
  num x = 0;
  num y = 0;
}

@NgDirective(
    selector: '[box]',
    map: const {
        "mouse": '=>mouse',
        "acceleration" : '=>acceleration'})
class BoxDirective extends LoopedAnimation {
  final Element element;
  final AnimationLoop animationLoop;

  num acceleration = 2.0;
  num friction = 0.5;
  num _vX = 0;
  num _vY =0;
  num _x = 0;
  num _targetX;
  num _y = 0;
  num _targetY;

  bool _playing = false;
  Mouse _mouse;
  set mouse(Mouse mouse) {
    _mouse = mouse;
    print("$mouse");
    if(mouse != null) {
      _playing = true;
      animationLoop.play(this);
    }
  }
  Mouse get mouse => _mouse;

  BoxDirective(this.element, this.animationLoop);

  bool update(num offset) {
    if(!mouse.x.isNaN)
      _targetX = mouse.x;
    if(!mouse.y.isNaN)
      _targetY = mouse.y;

    // relative x/y
    num rX = _targetX - _x;
    num rY = _targetY - _y;

    // Radius is the "make it a circle as it gets closer to the mouse"
    num radius = 0;

    // distance to the mouse
    num length = sqrt((rX * rX) + (rY * rY));

    // normalize the vector
    rX = rX / length;
    rY = rY / length;
    
    rX = rX * acceleration;
    rY = rY * acceleration;

    if (length.isNaN
        || ((_vX*_vX + _vY*_vY) < acceleration * acceleration)
        && length < acceleration) {
      _x = _targetX;
      _y = _targetY;
      _vX = 0;
      _vY = 0;
      radius = 50;

    } else {
      // NOTE, this doesn't take time into account and should delta based on
      // offset.
      _vX += rX;
      _vY += rY;
      
      // friction, inverse to velocity
      num fX = -_vX;
      num fY = -_vY;
      num fL = sqrt((fX * fX) + (fY * fY));
      fX /= fL;
      fY /= fL;
      fX *= friction;
      fY *= friction;
      
      _vX += fX;
      _vY += fY;

      _x += _vX;
      _y += _vY;

      radius = 100 - length / 2;
      radius = radius < 0 ? 0 : radius;
    }

    element.style.top = "${_y - 50}px";
    element.style.left = "${_x - 50}px";
    element.style.borderRadius = "${radius}px";
    return _playing;
  }
}


