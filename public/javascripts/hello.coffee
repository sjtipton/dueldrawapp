$(document).ready ->
    myPath = new Path()
    myPath.strokeColor = "black"
    onMouseDown = (event) ->
      myPath.add event.point  if myPath.segments.length is 0
      myPath.add event.point
    onMouseDrag = (event) ->
      myPath.lastSegment.point = event.point
