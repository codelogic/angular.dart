library angular.animate.exp;

import 'dart:html';
import 'dart:async';

typedef CompletedAction(bool success);

abstract class NgAnimateVisibility {
  static const String NG_HIDE = "ng-hide";
  AnimationHandle show(Element element);
  AnimationHandle hide(Element element);
}

abstract class NgAnimateCss {
  AnimationHandle addClass(Element element, String cssClass);
  AnimationHandle removeClass(Element element, String cssClass);
}

abstract class NgAnimateDom {
  AnimationHandle insert(Iterable<Node> nodes, Node parent,
      { Node insertBefore});
  AnimationHandle remove(Iterable<Node> nodes);
  AnimationHandle move(Iterable<Node> nodes, Node parent,
      { Node insertBefore });
}

class NoAnimateDom extends NgAnimateDom {
  AnimationHandle insert(Iterable<Node> nodes, Node parent,
      { Node insertBefore }) {
    _domInsert(nodes, parent, insertBefore: insertBefore);
    return new _CompletedAnimationHandle();
  }

  AnimationHandle remove(Iterable<Node> nodes) {
    _domRemove(nodes.toList(growable: false));
    return new _CompletedAnimationHandle();
  }

  AnimationHandle move(Iterable<Node> nodes, Node parent,
      { Node insertBefore }) {
    _domMove(nodes, parent, insertBefore: insertBefore);
    return new _CompletedAnimationHandle();
  }
}

class NoAnimateVisibility extends NgAnimateVisibility {
  AnimationHandle show(Element element) {
    element.classes.add(NgAnimateVisibility.NG_HIDE);
    return new _CompletedAnimationHandle();
  }

  AnimationHandle hide(Element element) {
    element.classes.remove(NgAnimateVisibility.NG_HIDE);
    return new _CompletedAnimationHandle();
  }
}

class NoAnimateCss extends NgAnimateCss {
  AnimationHandle addClass(Element element, String cssClass) {
    element.classes.add(cssClass);
    return new _CompletedAnimationHandle();
  }

  AnimationHandle removeClass(Element element, String cssClass) {
    element.classes.remove(cssClass);
    return new _CompletedAnimationHandle();
  }
}

class CssAnimateBase {
  static const String NG_ADD_POSTFIX = "-add";
  static const String NG_REMOVE_POSTFIX = "-remove";
  static const String NG_ACTIVE_POSTFIX = "-active";
  
  final CssAnimationOptimizer _optimizer;
  final AnimationLoop _animationLoop;

  CssAnimateBase(this._optimizer, this._animationLoop);
  
  AnimationHandle _cssAnimate(Element element, 
    String event,
    String eventActive,
    { String addAtStart,
      String addAtEnd,
      String removeAtStart,
      String removeAtEnd }) {

    var addAnimation = new CssAnimation(element, event, eventActive,
        addAtStart: addAtStart,
        addAtEnd: addAtEnd,
        removeAtStart: removeAtStart,
        removeAtEnd: removeAtEnd);

    _optimizer.track(addAnimation);
    _animationLoop.play(addAnimation);
    
    var handle = new _CssAnimationHandle(addAnimation, _animationLoop, _optimizer);
    
    addAnimation.onCompleted = ((success) {
      if(success) {
        handle.complete();
      } else {
        handle.cancel();
      }
    });
    return handle;
  }
}

class CssAnimateVisibility extends CssAnimateBase implements NgAnimateVisibility {
  static const String NG_HIDDEN = "ng-hidden";

  CssAnimateVisibility(CssAnimationOptimizer optimizer, AnimationLoop animationLoop)
      : super(optimizer, animationLoop);
  
  AnimationHandle hide(Element element) {
    if(!_optimizer.shouldAnimate(element)) {
      return new _CompletedAnimationHandle();
    }

    var eventShow = "${NgAnimateVisibility.NG_HIDE}${CssAnimateBase.NG_REMOVE_POSTFIX}";
    var eventShowActive = "$eventShow${CssAnimateBase.NG_ACTIVE_POSTFIX}";
    
    var show = _optimizer.findExisting(element,
        [eventShow, eventShowActive]);
    
    if(show != null) {
      show.cancel();
    }
    
    var eventHide = "${NgAnimateVisibility.NG_HIDE}${CssAnimateBase.NG_ADD_POSTFIX}";
    var eventHideActive = "$eventHide${CssAnimateBase.NG_ACTIVE_POSTFIX}";   
    return _cssAnimate(element, eventHide, eventHideActive,
        addAtEnd: NgAnimateVisibility.NG_HIDE);
  }
  
  AnimationHandle show(Element element) {
    if(!_optimizer.shouldAnimate(element)) {
      return new _CompletedAnimationHandle();
    }

    var eventHide = "${NgAnimateVisibility.NG_HIDE}${CssAnimateBase.NG_ADD_POSTFIX}";
    var eventHideActive = "$eventHide${CssAnimateBase.NG_ACTIVE_POSTFIX}";
    
    var hideAnimation = _optimizer.findExisting(element,
        [eventHide, eventHideActive]);
    
    if(hideAnimation != null) {
      hideAnimation.cancel();
    }
    
    // remove: ng-hide
    // add:    ng-hide-remove
    // add:    ng-hidden
    // frame
    // add:    ng-hide-remove-active
    // frames....
    // remove: ng-hidden
    // remove: ng-hide-remove
    // remove: ng-hide-remove-active
    
    var eventShow = "${NgAnimateVisibility.NG_HIDE}${CssAnimateBase.NG_REMOVE_POSTFIX}";
    var eventShowActive = "$eventShow${CssAnimateBase.NG_ACTIVE_POSTFIX}";
    
    return _cssAnimate(element,
        eventShow,
        eventShowActive,
        removeAtStart: NgAnimateVisibility.NG_HIDE,
        addAtStart: NG_HIDDEN,
        removeAtEnd: NG_HIDDEN);
  }
}

class CssAnimateCss extends CssAnimateBase implements NgAnimateCss {

  CssAnimateCss(CssAnimationOptimizer optimizer, AnimationLoop animationLoop)
      : super(optimizer, animationLoop);
  
  AnimationHandle addClass(Element element, String cssClass) {
    if(!_optimizer.shouldAnimate(element)) {
      return new _CompletedAnimationHandle();
    }
    
    var eventAdd = "$cssClass${CssAnimateBase.NG_ADD_POSTFIX}";
    var eventAddActive = "$eventAdd${CssAnimateBase.NG_ACTIVE_POSTFIX}";
    var eventRemove = "$cssClass${CssAnimateBase.NG_REMOVE_POSTFIX}";
    var eventRemoveActive = "$eventRemove${CssAnimateBase.NG_ACTIVE_POSTFIX}";
    
    var removeAnimation = _optimizer.findExisting(element,
        [eventRemove, eventRemoveActive]);
    
    if(removeAnimation != null) {
      removeAnimation.cancel();
    }
    
    return _cssAnimate(element, eventAdd, eventAddActive, addAtEnd: cssClass);
  }
  
  AnimationHandle removeClass(Element element, String cssClass) {
    if(!_optimizer.shouldAnimate(element)) {
      return new _CompletedAnimationHandle();
    }

    var eventAdd = "$cssClass${CssAnimateBase.NG_ADD_POSTFIX}";
    var eventAddActive = "$eventAdd${CssAnimateBase.NG_ACTIVE_POSTFIX}";
    var eventRemove = "$cssClass${CssAnimateBase.NG_REMOVE_POSTFIX}";
    var eventRemoveActive = "$eventRemove${CssAnimateBase.NG_ACTIVE_POSTFIX}";

    var addAnimation = _optimizer.findExisting(element,
        [eventAdd, eventAddActive]);

    if(addAnimation != null) {
      addAnimation.cancel();
    }       
    return _cssAnimate(element, eventRemove, eventRemoveActive, removeAtEnd: cssClass);
  }
}

class CssAnimationOptimizer {
  final Map<Element, Set<CssAnimation>> cssAnimations
    = new Map<Element, Set<CssAnimation>>();
  final AnimationOptimizer _optimizer;
  
  CssAnimationOptimizer(AnimationOptimizer this._optimizer);
  
  track(CssAnimation animation) {
    var animations = cssAnimations.putIfAbsent(animation.element, ()
        => new Set<Animation>());
    animations.add(animation);
    
    _optimizer.track(animation.element, animation);
  }
  
  forget(CssAnimation animation) {
    var animations = cssAnimations[animation.element];
    animations.remove(animation);
    if(animations.length == 0) {
      cssAnimations.remove(animation.element);
    }

    _optimizer.forget(animation);
  }
  
  CssAnimation findExisting(Element element, List<String> classes) {
    var animations = cssAnimations[element];
    if(animations == null) return null;
    
    return animations.firstWhere((animation) =>
      classes.any((c) => c == animation.addAtStart
        || animation.addAtEnd
        || animation.removeAtStart
        || animation.removeAtEnd
        || animation.eventClass
        || animation.activeClass)
    , orElse: () => null);
  }
  
  bool shouldAnimate(Element element) {
    return _optimizer.shouldAnimate(element);
  }
}

class CssAnimation extends LoopingAnimation {
  static const num extraDuration = 16.0; // Two extra 60fps frames of duration.

  final Element element;
  final String addAtStart;
  final String addAtEnd;
  final String removeAtStart;
  final String removeAtEnd;

  final String eventClass;
  final String activeClass;

  bool _active = true;
  bool _started = false;

  num _startTime;
  num _duration;

  CssAnimation(Element this.element,
      this.eventClass,
      this.activeClass,
      { this.addAtStart,
        this.removeAtStart,
        this.addAtEnd,
        this.removeAtEnd }) {
    element.classes.add(eventClass);
  }

  void read(num timeInMs) {
    if(_active && _startTime == null) {
      _startTime = timeInMs;
      try {
        // computeLongestTransition return a value in milliseconds.
        _duration = computeLongestTransition(element.getComputedStyle()) * 1000
            + extraDuration;
      } catch (e) { }
    }
  }

  bool update(num timeInMs) {
    if(!_active) {
      return false;
    }
    
    // This happens if an animation is forcibly canceled or completed
    // outside of the update method.
    if(_active) {
      // This will always run after the first animationFrame is queued so that
      // inserted elements have the base event class applied before adding the
      // active class to the element. If this is not done, inserted dom nodes
      // will not run their enter animation.
      if(!_started && _duration > 0.0 && timeInMs >= _startTime) {
        element.classes.add(activeClass);
        if(addAtStart != null) {
          element.classes.add(addAtStart);
        } 
        if(removeAtStart != null) {
          element.classes.remove(removeAtStart);
        }
        _started = true;
      } else if (timeInMs >= _startTime + _duration) {
        complete();
        return false;
      }
      return true;
    }
  }

  void cancel() {
    if(_active) {
      _active = false;
      element.classes.remove(eventClass);
      element.classes.remove(activeClass);
      if(addAtStart != null) {
        element.classes.remove(addAtStart);
      } 
      if(removeAtEnd != null) {
        element.classes.add(removeAtEnd);
      }
      
      if(onCompleted != null) {
        onCompleted(false);
      }
    }
  }

  void complete() {
    if(_active) {
      _active = false;
      element.classes.remove(eventClass);
      element.classes.remove(activeClass);
      if(addAtEnd != null) {
        element.classes.add(addAtEnd);
      } 
      if(removeAtEnd != null) {
        element.classes.remove(removeAtEnd);
      }

      if(onCompleted != null) {
        onCompleted(true);
      }
    }
  }
}

abstract class Animation {
  CompletedAction onCompleted;
  void cancel() {}
  void complete() {}
}

abstract class LoopingAnimation extends Animation {
  void read(num timeInMs) {}
  bool update(num timeInMs);
}

abstract class AnimationHandle {
  void cancel();
  void complete();
}

class _CompletedAnimationHandle extends AnimationHandle {
  Future<bool> _future;
  get onCompleted {
    if(_future == null) {
      var completer = new Completer<bool>();
      completer.complete(true);
      _future = completer.future;
    }
    return _future;
  }

  complete() { }
  cancel() { }
}

class AnimationOptimizer {
  Map<Element, Set<Animation>> _elements;
  Map<Animation, Element> _animations;
  
  track(Element element, Animation animation) {
    var animations = _elements.putIfAbsent(element, ()
        => new Set<Animation>());
    
    animations.add(animation);
    _animations[animation] = element;
  }
  
  forget(Animation animation) {
    var element = _animations.remove(animation);
    if(element != null) {
      var set = _elements[element];
      set.remove(element);
      // It may be more efficient just to keep sets around even after
      // animations complete.
      if(set.length == 0) {
        _elements.remove(element);
      }
    } 
  }
  
  contains(Element element) {
    return _elements.containsKey(element);
  }
  
  bool shouldAnimate(Element element) {
    if(element.parent == null)
      return true;
    if(contains(element.parent))
      return false;
    return shouldAnimate(element);
  }
}

class AnimationLoop {
  List<LoopingAnimation> _animations = [];
  bool _animationFrameQueued = false;
  Window _wnd;

  AnimationLoop(Window this._wnd);

  play(LoopingAnimation animation) {
    _animations.add(animation);
    _queueAnimationFrame();
  }

  _queueAnimationFrame() {
    if (!_animationFrameQueued) {
      _animationFrameQueued = true;

      _wnd.animationFrame.then((offsetMs) => _animationFrame(offsetMs));
    }
  }

  _animationFrame(num timeInMs) {
    _animationFrameQueued = false;

    for (int i = 0; i < _animations.length; i++) {
      _animations[i].read(timeInMs);
    }

    for (int i = 0; i < _animations.length; i++) {
      _animations[i].update(timeInMs);
    }

    if (_animations.length > 0) {
      _queueAnimationFrame();
    }
  }

  forget(LoopingAnimation animation) {
    _animations.remove(animation);
  }
}

class _CssAnimationHandle extends AnimationHandle {
  final AnimationLoop _runner;
  final LoopingAnimation _animation;
  final CssAnimationOptimizer _optimizer;

  _CssAnimationHandle(this._animation, this._runner, this._optimizer) {
    assert(_runner != null);
    assert(_animation != null);
  }

  complete() {
    _runner.forget(_animation);
    _optimizer.forget(_animation);
    _animation.complete();
  }

  cancel() {
    _runner.forget(_animation);
    _optimizer.forget(_animation);
    _animation.cancel();
  }
}


void _domRemove(List<Node> nodes) {
  // Not every element is sequential if the list of nodes only
  // includes the elements. Removing a block also includes
  // removing non-element nodes inbetween.
  for(var j = 0, jj = nodes.length; j < jj; j++) {
    Node current = nodes[j];
    Node next = j+1 < jj ? nodes[j+1] : null;

    while(next != null && current.nextNode != next) {
      current.nextNode.remove();
    }
    nodes[j].remove();
  }
}

List<Node> _allNodesBetween(List<Node> nodes) {
  var result = [];
  // Not every element is sequential if the list of nodes only
  // includes the elements. Removing a block also includes
  // removing non-element nodes inbetween.
  for(var j = 0, jj = nodes.length; j < jj; j++) {
    Node current = nodes[j];
    Node next = j+1 < jj ? nodes[j+1] : null;

    while(next != null && current.nextNode != next) {
      result.add(current.nextNode);
      current = current.nextNode;
    }
    result.add(nodes[j]);
  }
  return result;
}

void _domInsert(Iterable<Node> nodes, Node parent,
                { Node insertBefore }) {
  parent.insertAllBefore(nodes, insertBefore);
}

void _domMove(Iterable<Node> nodes, Node parent,
              { Node insertBefore }) {
  nodes.forEach((n) {
    if(n.parentNode == null) n.remove();
      parent.insertBefore(n, insertBefore);
  });
}

num computeLongestTransition(dynamic style) {
  double longestTransition = 0.0;
    
  if(style.transitionDuration.length > 0) {
    // Parse transitions
    List<double> durations = _parseDurationList(style.transitionDuration)
        .toList();
    List<double> delays = _parseDurationList(style.transitionDelay)
        .toList();
      
    assert(durations.length == delays.length);
      
    for(int i = 0; i < durations.length; i++) {
      var total = _computeTotalDurationSeconds(delays[i], durations[i]);
      if(total > longestTransition)
        longestTransition = total;
    }
  }
    
  if(style.animationDuration.length > 0) {
    // Parse and add animation duration properties.
    List<num> animationDurations = 
        _parseDurationList(style.animationDuration).toList(growable: false);
    // Note that animation iteration count only affects duration NOT delay.
    List<num> animationDelays = 
        _parseDurationList(style.animationDelay).toList(growable: false);
    
    List<num> iterationCounts = _parseIterationCounts(
        style.animationIterationCount).toList(growable: false);
    
    assert(animationDurations.length == animationDelays.length);
    
    for(int i = 0; i < animationDurations.length; i++) {
      var total = _computeTotalDurationSeconds(
          animationDelays[i], animationDurations[i],
          iterations: iterationCounts[i]);
      if(total > longestTransition)
        longestTransition = total;
    }
  }
 
  return longestTransition;
}
  
Iterable<num> _parseIterationCounts(String iterationCounts) {
  return iterationCounts.split(", ")
          .map((x) => x == "infinite" ? -1 : num.parse(x));
}

/// This expects a string in the form "0s, 3.234s, 10s" and will return a list
/// of doubles of (0, 3.234, 10).
Iterable<num> _parseDurationList(String durations) {
  // Substring removes the 's' from the end.
  return durations.split(", ")
      .map((x) => _parseCssDuration(x));
}

/// This expects a string in the form of '0.234s' or '4s' and will return
/// a parsed double.
num _parseCssDuration(String cssDuration) {
  return double.parse(cssDuration.substring(0, cssDuration.length - 1));
}

num _computeTotalDurationSeconds(num delay, num duration,
    { int iterations: 1}) {
  if (iterations == 0)
    return 0.0;
  if (iterations < 0) // infinite
    iterations = 1;
  
  return (duration * iterations) + delay;
}