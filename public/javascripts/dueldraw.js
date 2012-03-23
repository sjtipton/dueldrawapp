function clearCanvas() {
  var canvas = document.getElementById("canvas-1");
  var ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  canvas.width = canvas.width + 1;
  width = canvas.width;
  canvas.width = width - 1;
  canvas.save();
}