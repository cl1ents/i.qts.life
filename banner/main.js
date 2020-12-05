var c = document.querySelector("#c")

c.width = 1920;
c.height = 250;
var x = c.getContext("2d");

var Interval = setInterval(draw, 1000/60)

var S = Math.sin;
var C = Math.cos;
var T = Math.tan;
function R(r,g,b,a) 
{
  a = a === undefined ? 1 : a;
  return "rgba("+(r|0)+","+(g|0)+","+(b|0)+","+a+")"
}

var Time = 0
function draw()
{
    u(Time)
    Time += 1 / 60
}
function reload()
{
    clearInterval(Interval)
    c.height = 1080
    Time = 0
    Interval = setInterval(draw, 1000/60)
}

var cofiImg = new Image()
cofiImg.src = "https://i.qts.life/res/java.png"
function u(t)
{
    c.height = 250
    x.strokeStyle="white"
    x.beginPath()
    x.moveTo(0, S(t*5) * -50 + 125)
    for(i=0;i<1920;i++)
    {
        // Rainbow BG
        x.fillStyle=`hsl(${i/15+t*100},100%,60%`
        x.fillRect(i,S(t*5+i/300) * -50 + 125,1,S(t*5+i/300) * 50 + 125)
        // Sine wave
        x.lineTo(i, S(t*5+i/300) * -50 + 125)
    }
    x.lineWidth = 10
    x.stroke()
    x.drawImage(cofiImg, 875, S(t*2)*20+50, 150, 150)
    //x.fillStyle=R()
    //x.font='300px a';
    //x.fillText('☕',750,S(t*2)*20+630); // fuck cats, all my homies hate cats
}

reload()