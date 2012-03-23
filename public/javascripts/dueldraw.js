function clearCanvas() {
  var canvas = document.getElementById("canvas-1");
  var context = canvas.getContext("2d");
  context.clearRect(0, 0, canvas.width, canvas.height);
}