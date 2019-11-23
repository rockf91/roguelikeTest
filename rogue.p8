pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
 t=0
 p_ani={240, 241, 242, 243}
 
 dirx={-1,1,0,0,1,1,-1,-1}
 diry={0,0,-1,1,-1,1,1,-1}
 
 mob_ani={240, 192}
 mob_atk={1, 1}
 mob_hp={5, 2}
 
 debug={}
 
 _upd = update_game
 _drw = draw_game
 startgame()
end

function _update60()
 t+=1
 _upd()
 dofloats()
end

function _draw()
 _drw()
 drawind()
 cursor(4,4)
 color(8)
 for txt in all(debug) do
  print(txt)
 end
end

function startgame()
 buttbuff=-1
 
 mob={}
 p_mob=addmob(1,3,4)
 
 for x=0,15 do
  for y=0,15 do
   if mget(x,y)==192 then
    addmob(2,x,y)
    mset(x,y,1)
   end
  end
 end
 
 p_t=0

 wind={}
 float={}
 talkwind=nil
end

-->8
--updates
function update_game()
 if talkwind then
  if getbutt()==5 then
   talkwind.dur=0
   talkwind=nil
  end
 else
	 dobuttbuff()
	 dobutt(buttbuff)
	 buttbuff=-1
 end
end

function update_pturn()
 dobuttbuff()
 p_t=min(p_t+0.2,1)
 
 p_mob.mov(p_mob,p_t)
 
 if p_t == 1 then
  _upd=update_game
  doai()
	end
end

function update_aiturn()
 dobuttbuff()
 p_t=min(p_t+0.125,1)
 
 for m in all(mob) do
  if m!=p_mob and m.mov then
    m.mov(m,p_t)
  end
 end
 if p_t == 1 then
  _upd=update_game
	end
end

function update_gameover()

end

function dobuttbuff()
 if buttbuff==-1 then
  buttbuff=getbutt()
 end
end

function getbutt()
 for i=0,5 do
  if btnp(i) then
   return i
  end
 end
 return -1
end

function dobutt(butt)
 if butt<0 then return end
 if butt<4 then
  moveplayer(dirx[butt+1],diry[butt+1])
 end
 -- menu button
end
-->8
--draws
function draw_game()
 cls(0)
 map()
 
-- drawspr(getframe(p_ani),p_x*8,p_y*8,9)
-- drawspr(getframe(p_ani),p_x*8+p_ox,p_y*8+p_oy,10,p_flip)
 for m in all(mob) do
  local col=10
  if m.flash>0 then
   m.flash-=1
   col=7
  end
  drawspr(getframe(m.ani),m.x*8+m.ox,m.y*8+m.oy,col,m.flp)
 end
 
 for f in all(float) do
  oprint8(f.txt,f.x,f.y,f.c,0)
 end
end

function draw_gameover()

end
-->8
--tools
function getframe(ani)
 return ani[flr(t/8)%#ani+1]
end

function drawspr(_spr,_x,_y,_c,_flip)
 palt(0, false)
 pal(6, _c)
 spr(_spr,_x,_y,1,1,_flip)
 pal()
end

function rectfill2(_x,_y,_w,_h,_c)
 rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end

function oprint8(_t,_x,_y,_c,_c2)
 for i=1,8 do
  print(_t,_x+dirx[i],_y+diry[i],_c2)
 end 
 print(_t,_x,_y,_c)
end

function dist(fx,fy,tx,ty)
 local dx,dy=fx-tx,fy-ty
 return sqrt(dx*dx+dy*dy)
end
-->8
--grameplay

function moveplayer(dx,dy)
 local destx,desty=p_mob.x+dx,p_mob.y+dy
 local tle=mget(destx,desty)
 
 if iswalkable(destx,desty,"checkmobs") then
  sfx(63)
  mobwalk(p_mob,dx,dy)
  p_t=0
  _upd=update_pturn
 else
  --not walkable
  mobbump(p_mob,dx,dy)
	 p_t=0
	 _upd=update_pturn
	 
	 local mob=getmob(destx,desty)
	 if mob==false then
	  if fget(tle,1)then
	   trig_bump(tle,destx,desty)
		 end
		else
		 sfx(58)
		 hitmob(p_mob,mob)
	 end
 end
 
end

function trig_bump(tle,destx,desty)
 if tle==7 or tle==8 then
 --vase
  sfx(59)
  mset(destx,desty,1)
 elseif tle==10 or tle==12 then
 --chests
  sfx(61)
  mset(destx,desty,tle-1)
 elseif tle==13 then
 --door
  sfx(62)
  mset(destx,desty,1)
 elseif tle==6 then
 --stone
  --showmsg("hello",120)
  showmsg({"wedsfdsfsd dsf dsdf","","climb the tower","to obtean sdf"})
  --addwind(32,64,64,24,{"hello world","this is line 2"})
 end

end

function getmob(x,y)
 for m in all(mob) do
  if m.x==x and m.y==y then
   return m
  end
 end
 return false
end

function iswalkable(x,y,mode)
 if mode== nil then mode="" end
 if inbounds(x,y) then
  local tle=mget(x,y)
  if fget(tle,0)==false then
   if mode=="checkmobs" then
    return getmob(x,y)==false
   end
   return true
  end
 end
 return false
end

function inbounds(x,y)
 return not (x<0 or y<0 or x>15 or y>15)
end

function hitmob(atkm,defm)
 local dmg=atkm.atk
 defm.hp-=dmg
 defm.flash=10
 
 addfloat("-"..dmg,defm.x*8,defm.y*8,9)
 
 if defm.hp<=0 then
  del(mob,defm)
 end
end
-->8
--ui

function addwind(_x,_y,_w,_h,_txt)
 local w={x=_x,y=_y,w=_w,h=_h,txt=_txt}
 add(wind,w)
 return w
end

function drawind()
 for w in all(wind) do
  local wx,wy,ww,wh=w.x,w.y,w.w,w.h
  rectfill2(wx,wy,ww,wh,0)
  rect(wx+1,wy+1,wx+ww-2,wy+wh-2,6)
  wx+=4
  wy+=4
  clip(wx,wy,ww-8,wh-8)
  for i=1, #w.txt do
   local txt=w.txt[i]
   print(txt,wx,wy,6)
   wy+=6
  end
  clip()
  
  if w.dur != nil then
   w.dur-=1
   if w.dur<=0 then
    local dif=wh/4
    w.y+=dif/2
    w.h-=dif
    if w.h<3 then
     del(wind,w)
    end
   end
  else
    if w.butt then
     oprint8("❎",wx+ww-15,wy-1+sin(time()),6,0)
    end
  end
  
 end
end

function showmsg(txt,dur)
 local wid=(#txt+2)*4+7
 
 local w=addwind(63-wid/2,50,wid,13,{" "..txt})
 w.dur=dur
end

function showmsg(txt)
 talkwind=addwind(16,50,94,#txt*6+7,txt)
 talkwind.butt=true
end

function addfloat(_txt,_x,_y,_c)
 add(float,{txt=_txt,x=_x,y=_y,c=_c,ty=_y-10,t=0})
end

function dofloats()
 for f in all(float) do
  f.y+=(f.ty-f.y)/10
  f.t+=1
  if f.t>70 then
   del(float,f)
  end
 end
end
-->8
--mobs

function addmob(typ,mx,my)
 local m={
  x=mx,
  y=my,
  ox=0,
  oy=0,
  sox=0,
  soy=0,
  flp=false,
  mov=nil,
  ani={},
  flash=0,
  hp=mob_hp[typ],
  hpmax=mob_hp[typ],
  atk=mob_atk[typ]
 }
 for i=0,3 do
  add(m.ani,mob_ani[typ]+i)
 end
 add(mob,m)
 return m
end

function mobwalk(mb,dx,dy)
	mb.x+=dx
	mb.y+=dy
	
	mobflip(mb,dx)
	mb.sox,mb.soy=-dx*8,-dy*8
 mb.ox,mb.oy=mb.sox,mb.soy
	mb.mov=mov_walk
end

function mobbump(mb,dx,dy)
 mobflip(mb,dx)
	mb.sox,mb.soy=dx*8,dy*8
	mb.ox,mb.oy=0,0
	mb.mov=mov_bump
end

function mobflip(mb,dx)
 if dx<0 then
	 mb.flp=true
	elseif dx>0 then
		mb.flp=false
	end
end

function mov_walk(mob,at)
 mob.ox=mob.sox*(1-at)
 mob.oy=mob.soy*(1-at)
end

function mov_bump(mob,at)
 --★
 local tme=at
 if at>0.5 then
  tme=1-at
 end
 mob.ox=mob.sox*tme
 mob.oy=mob.soy*tme
end

function doai()
 --debug={}
 for m in all(mob) do
  if m!=p_mob then
   m.mov=nil
   if dist(m.x,m.y,p_mob.x,p_mob.y)==1 then 
     --attack player
     dx,dy=p_mob.x-m.x,p_mob.y-m.y
     mobbump(m,dx,dy)
     hitmob(m,p_mob)
     sfx(57)
   else
     --move to player
    local bdst,bx,by=999,0,0
    for i=1,4 do
     local dx,dy=dirx[i],diry[i]
     local tx,ty=m.x+dx,m.y+dy
     if iswalkable(tx,ty,"checkmobs") then
      local dst=dist(tx,ty,p_mob.x,p_mob.y)
      if dst<bdst then
       bdst,bx,by=dst,dx,dy
      end
     end 
    end
    mobwalk(m,bx,by)
    _upd=update_aiturn
    p_t=0
   end
  end
 end
end
__gfx__
000000000000000066606660000000006660666066606660aaaaaaaa00aaa00000aaa00000000000000000000000000000aaa000a0aaa0a0a000000055555550
000000000000000000000000000000000000000000000000aaaaaaaa0a000a000a000a00066666600aaaaaa066666660a0aaa0a000000000a0aa000000000000
007007000000000060666060000000006066606060000060a000000a0a000a000a000a00060000600a0000a060000060a00000a0a0aaa0a0a0aa0aa055000000
00077000000000000000000000000000000000000000000000aa0a0000aaa000a0aaa0a0060000600a0aa0a060000060a00a00a000aaa00000aa0aa055055000
000770000000000066606660000000000000000060000060a000000a0a00aa00aa00aaa0066666600aaaaaa066666660aaa0aaa0a0aaa0a0a0000aa055055050
007007000005000000000000000000000005000000000000a0a0aa0a0aaaaa000aaaaa000000000000000000000000000000000000aaa000a0aa000055055050
000000000000000060666060000000000000000060666060a000000a00aaa00000aaa000066666600aaaaaa066666660aaaaaaa0a0aaa0a0a0aa0aa055055050
000000000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006666660666666000666666006666600666666006660666066666660000066606660000066666660000066600000666066600000
00000000000000000000000066666660666666606666666066666660666666606660666066666660000066606660000066666660000066600000666066600000
00000000000000000000000066666660666666606666666066666660666666606660066066666660000006606600000066666660000066600000066066600000
00000000000000000000000066600000000066606660000066606660000066606660000000000000000000000000000000000000000066600000000066600000
00000660666666606600000066600000000066606660666066606660666066606660066066000660660006606600066000000660660066606666666066600660
00006660666666606660000066600000000066606660666066606660666066606660666066606660666066606660666000006660666066606666666066606660
00006660666666606660000066600000000066606660666066606660666066606660666066606660666066606660666000006660666066606666666066606660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660066666006660000066600000000066600666666066606660666666006660666066606660666066606660666066606660666000006660666066666660
00006660666666606660000066600000000066606666666066606660666666606660666066606660666066606660666066606660666000006660666066666660
00006660666666606660000066600000000066606666666066000660666666606600066066006660660006606600066066600660660000006600666066666660
00006660666066606660000066600000000066606660000000000000000066600000000000006660000000000000000066600000000000000000666000000000
00006660666666606660000066666660666666606666666066000660666666606666666066006660000006606600000066600000666666600000666066000000
00006660666666606660000066666660666666606666666066606660666666606666666066606660000066606660000066600000666666600000666066600000
00006660066666006660000006666660666666000666666066606660666666006666666066606660000066606660000066600000666666600000666066600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005000000088000088
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005055000080000008
00000660666666606600000066666660666066606660666066606660666066600000066066000000000006600000000066000660660000005055055000000000
00000000000000000000000000000000666066606660000066606660000066600000000000000000000000000000000000000000000000000055055000000000
00000000000000000000000066666660666066606666666066666660666666606600000000000660000006606600066000000000660000005000055000000000
00000000000000000000000066666660666066606666666066666660666666606660000000006660000066606660666000000000666000005055000000000000
00000000000000000000000066666660666066600666666006666600666666006660000000006660000066606660666000000000666000005055055080000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000088
06000000000000000000060000000000505050506660666000000000000550000000000000000000000000000000000000000000000000000000000000000000
60000000060000000000006000000600000000000000000000500500000000500500005005050050005000000000005000500000000000000000000000000000
66000000660000000000066000000660505050506066606000050000055005000500005005000000000005000050055000000500000000000000000000000000
00000000000000000000000000000000000000000000000005050000555050000005000000005000000000000000000005000000000000000000000000000000
66000000660000000000066000000660505050505050505000005050000050500005050000005050000000000000000000055000000000000000000000000000
0005000000050000000500000005000000000000000000000050500000050000050505000500005000050000005500500050050000aaaaa00000000000000000
600000006000000000000060000000605050505050505050000050000005000005000000050500500000000005555000005550000aaaaaaaa000000000aaaa00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0aaaaaaaa00000aaaaaaa0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000a00aaaaaaaaaaaaaaaaaaaaa
cc7777cc7777ccccccccccccccccccccc77777777cccccccccccccccccccccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaa
ccc77cccc77ccccccccccccccccccccccc77cccc77ccccccccccccccccccccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaa0a
cccc77cc77cc77777cc7777cc7777ccccc77ccccc77cc777777c7777777cccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaa0aa
ccccc7777cc77ccc77cc77cccc77cccccc77cccccc77cc77cc7cc77ccc77ccc77ccccccc000000000000000000000000000000000aaaaaaaaaaaaaaaaaaa0aa0
ccccc7777c77ccccc77c77cccc77cccccc77cccccc77cc77ccccc77cccc77cc77ccccccc0000000000000000000000000000000000aaaaaaaaaaaaaaa0a0a0a0
cccccc77cc77ccccc77c77cccc77cccccc77cccccc77cc7777ccc77cccc77cc77ccccccc00000000000000000000000000000000a00aaa0a0a0a0a0a0a0a0a0a
cccccc77cc77ccccc77c77cccc77cccccc77cccccc77cc77ccccc77cccc77cc77ccccccc00000000000000000000000000000000a0000aaaa0a0a0a0a0aaa00a
cccccc77cc77ccccc77c77cccc77cccccc77ccccc77ccc77ccccc77cccc77cc77ccccccc00000000000000000000000000000000aa000000aaaaaaaaaaa000aa
cccccc77ccc77ccc77ccc77cc77ccccccc77cccc77cccc77cc7cc77ccc77cccccccccccc00000000000000000000000000000000aa000aa000000000000000aa
ccccc7777ccc77777ccccc7777ccccccc77777777cccc777777c7777777cccc77ccccccc000000000000000000000000000000000aa0000aaaaaaaaaa0000aa0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000a0aa00000000000000aa0a0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000a00aa0000000000aa00a00
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000aa00aaaaaaaaaa00aa000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000aa0000000000aa00000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000aaaaaaaaaa0000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cc7777cc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccccccccccccccccc77ccccccc000000000000000000000000
ccc77cc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777ccc77cccccccccccccccccc77ccccccc000000000000000000000000
ccc77c77cccc7777c777777c7777ccc777777ccccc77cccccc7777cccc77ccccccccc77cccc77c777777c77777777cc77ccccccc000000000000000000000000
ccc7777cccccc77ccc77cc7cc77ccccc77cc77ccc7777cccc77c77ccc7777ccccccc77ccccccccc77cc7cccc77cc7cc77ccccccc000000000000000000000000
ccc777ccccccc77ccc77ccccc77ccccc77cc77ccc7cc7cccc77cccccc7cc7ccccccc77ccccccccc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc7777cccccc77ccc7777ccc777cccc77777ccc77cc7ccccc77cccc77cc7ccccccc77cccc7777c7777ccccc77ccccc77ccccccc000000000000000000000000
ccc77777ccccc77ccc77cccc777ccccc77cc77cc777777ccccc77ccc777777cccccc77ccccc77cc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc77c777cccc77ccc77ccccc77ccccc77cc77cc77cc77cccccc77cc77cc77ccccccc77cccc77cc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc77cc777ccc77ccc77cc7cc77cc7cc77cc77c77ccc77cc77cc77c77ccc77cccccccc77ccc77cc77cc7cccc77cccccccccccccc000000000000000000000000
cc7777cc777c7777c777777c777777c777777c7777cc777cc7777c7777cc777cccccccc77777cc777777ccc7777cccc77ccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
c0000000000000ccccccc000000000cc00000000000ccc0000000000000000000000000000000000000000000000000000000000000000cc0000000000000000
0000000000000000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000
00777777777770000c000077777770000777777777700007777777700777777077777777000077777707777777007777707777777777700c0000000000000000
0007777777777770000077777777777000777777777770007777770007777700077777700c0007777707777770007777707777777777700c0000000000000000
c00000777000777000077770000077770000777000777000007770000777000000077700ccc000777000077700007770000077700007700c0000000000000000
cc0000777000077700777000000000777000777000077700007770007770000c00077700cccc00777000077700077700000077700000700c0000000000000000
cccc007770000777007770000000007770007770000777000077700777000cccc0077700cccc00777000077700777000cc0077700000000c0000000000000000
cccc00777000077700770000000000077700777000077700007770777000ccccc0077700cccc0077700007770777000ccc007770007000cc0000000000000000
cccc0077700007700777007700077007770077700007700c00777777000cccccc0077700cccc007770000777777000cccc00777777700ccc0000000000000000
cccc0077700777700777007700077007770077700077700c0077777000ccccccc0077700cccc00777000077777000ccccc00777777700ccc0000000000000000
cccc007777777700077700770007700777007777777700cc00777777000cccccc0077700cccc007770000777777000cccc00777000700ccc0000000000000000
cccc0077777770000777000700070007770077777777000c007777777000ccccc0077700cccc0077700007777777000ccc007770000000cc0000000000000000
cccc007770000000077700000000000770007770077770000077707777000cccc0077700ccc000777000077707777000cc0077700000000c0000000000000000
cccc0077700000c000777000000000777000777000777700007770077770000cc0077700cc00007770000777007777000c0077700000700c0000000000000000
ccc000777000cccc00777000000000777000777000077770007770007777000000077700000700777000077700077770000077700007700c0000000000000000
cc00007770000ccc00077770000077770000777000007777007770000777770000077700007700777000077700007777700077700007700c0000000000000000
c0007777777000ccc0007777777777700007777700000777777777700077777700777777777707777770777777000777777777777777700c0000000000000000
c0077777777700cccc000077777770000077777770000077777777770000777707777777777707777770777777700007777777777777700c0000000000000000
c0000000000000ccccc000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000c0000000000000000
cc00000000000cccccccc000000000ccc000000000ccc000000000000cc000000000000000000000000000000000cc0000000000000000cc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
00000000000000000000000000000000000006000000000006000000000000000000000000060006000000000066006600066600000666000006660000066600
00000000006660000000000000000000006600600006600060066000006600000066006600060006006600660600060000660600006606000066060000660600
00666000060666000066600000000000006660606066600060666000006660600600060000600060060006000600060006666000066660000666606606666066
06066600060666000606660006666660066666006066006006666600600660600066606000666060006660600066606006666666066666660666660606666606
60666660066666006066666060066666600666000666660006660060066666000606660606666606066606060606060606666606006606060660660000660600
66666660066666006666666066666666606660000666600000666060006666000666060606060606060666060660660666066000066000006606600006600000
06666600006660000666660006666660006666000066660006666000066660000606666006606660066606600666666006606600006600000060660000660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666000000066000000000000000000000000000000000000000000000666000000000000666600006666000066666600666600
00666600000000000066660006600600000666600000660000000000000066000000000000066600006666660006660000066666000660660006606600066066
06600060006666660660006006000000000606000006666000006600000666600006660000666666006666060066666600666666006666660066660000666666
06660000066600000666000006660000060666660006060000066660000606000066666600666606066666660066660600060000000600000006000000060000
00666600006666000066660000666600066666060606666600060600060666660066660606666666066666000666666600006600060066000000660006006600
06066066060660660606606606066066006660000666660606066666066666060666666606666600066666660666660000006660060066600000666006006660
06060660060606600606066006060660000000000066600006666606006660000666660006666666066606060666666606666600006666000666660000666600
00000000000000000000000000000000000000000000000000666000000000000666666606660606066660000666060600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000606000000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
00060600006666000006060000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00666600000606660066660000060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000
00060666000666660006066600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
06066666006000000006666606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
66000000066066000660000066066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66066606066066000660660066066606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600600000660000060060000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010000000303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101020201010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101020201010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201020202020108060c02020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201020f0101010101010e02c001010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201020202010102020102020201020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010102010101020d02010101020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201c00102010101010101c00101020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020101010201c001010101010101020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101c00101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000003050080500c050110500e050120501a050190502001022010230102d020260202e0502602026020230501c020250202602024020200201f0201d0201c02017030190501805017050160501505013050
010100001272017720117100170001700017000170001700007000170001700017000070000700007000070000700007000070000700007000070000700007000070000700007000070000700000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000018050180500a0501f05008050090500000012050110500f05009050080500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000180500605006050150500f0500b0500805005050050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000175501a5502055026550285502a5500000000000000000000000000000001e550205502155000000000000000000000000001c5501c5501c55000000000000000000000000001f550225502555027550
0001000025220252201b2201a22027220242101e2101c2101821014210112100d2300b2300a230092300923009230092300923009230092300000000000000000000000000000000000000000000000000000000
000100002105021050110500e050330203502035020290102a0202502000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002702029020250302502012020110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000013730187300f7200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
