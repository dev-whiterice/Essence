using Toybox.System;

public var bboxes = [];
public var boundingBoxes = [];

public function checkBoundingBoxes(points) {
  for (var i = 0; i < boundingBoxes.size(); i++) {
    var currentBounds = boundingBoxes[i];
    if (checkBoundsForComplication(points, currentBounds["bounds"])) {
      return currentBounds["complicationId"];
    }
  }
  return false;
}
public function checkBoundsForComplication(points, boundingBox) {
  return boxContains(points, boundingBox[0], boundingBox[1]);
}

public function boxContains(points, boxMinXY, boxMaxXY) {
  return (
    points[0] <= boxMaxXY[0] &&
    points[1] <= boxMaxXY[1] &&
    points[0] >= boxMinXY[0] &&
    points[1] >= boxMinXY[1]
  );
}
