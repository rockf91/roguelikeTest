pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--ld48 totem
--benjamin soule
focus_max=16
hp_max=20
refill_max=32

--from=5

shid=0
--test_seq={6,9,6,9,6,12,5,5,10,13,9} --4

function _init()
 t=0
 logs={} 
 pixels={}
 tipis={}
 first=true
 
 -- spirits 
 spirits={}
 for i=0,5 do add(spirits,32+i) end
 
 --
 --init_title()
 launch()
 --reset()
 --set_arena(0)
 ---

end

function init_title()

 mdr=function()
  sspr(24,96,13*8,24,12,0)
  vis=t%16<12
  if launching then
   vis=t%2==0
  end
  if vis then
   print("press x to start",34,80,7)
  end
 end
 
 mupd=function()
  if launching then
   if t==40 then
    launch()
   end
  else
   if btnp(5)  then
    launching=0
    t=0
    sfx(23)
   end
  end
  
  
 end

end

function launch()
 
 reset()
 set_arena(0)
 mupd=upd_game
 mdr=dr_game
end


function upd_game()
 foreach(ents,upe) 
 if gmo then return end
 
 if boss and boss.dhp<=0 then
  explode(boss)
 elseif hero and hero.dhp<=0 then
  explode(hero)
 end
end


function reset()
 reload()
 
 monsters={}
 ents={}
 t=0
 gmo=nil
 boss=nil
 
 -- hero
 hero=mke(16,32,32)
 hero.upd=upd_hero
 hero.recx=true 
 hero.hid=32 
 hero.hero=true
 hero.ady=0
 init_human(hero)
 refill=0
 
 
 arrows_max=5
 arrows=arrows_max
 
 if test_head then
  hero.hid=test_head
 end


end


function set_arena(k)
 a={ 0, 0, 64,16,0, 				
 				0, 24,16,8, 1,
 				24,16,16,16,0,
 				40,16,24,16,1,
 				64,16,24,8, 0,
 				0, 16,24,8, 0,
  }
 function f(n) return a[k*5+n] end
 arena={
  x=f(1),y=f(2),w=f(3),h=f(4),
  bg=k,roof=f(5)==1
 }
 -- scan
 wps={}

 for x=0,arena.w-1 do
  for y=0,arena.h-1 do
   px=arena.x+x
   py=arena.y+y
			fr=mget(px,py)
			if fr==32 then			
			 hero.x=x*8
			 hero.y=y*8
			 hero.vx=0
			 hero.vy=0
			 hero.jump=true

			 mset(px,py,0)
			end
			if fr<41 and fr>32 then	
			 mk_boss(fr,x*8,y*8+8)	
			 mset(px,py,0)
			end 
			if fr==1 or fr==2 then
			 rep={0,148}
			 mset(px,py,rep[fr])
			 add(wps,{x=x*8,y=y*8})
			end	
			if fr==155 then
			 add(wps,{x=x*8,y=(y-1)*8})
			end		
			if fr==101 and first then
			 add(tipis,{x=x,y=y,n=#tipis,ok=#tipis<5})
			 --add(tipis,{x=x,y=y,n=#tipis,ok=true})
			end					
  end
 end
 first=false
 place_cam()
 secure_swap(0)
 if quiver then kill(quiver) end
 if arena.bg==0 and from!=nil then
  tipi=tipis[from+1]
  hero.x=tipi.x*8+16
  hero.y=tipi.y*8
  hero.flp=true
 end 
 fade(true)
 
end

function init_human(e)
 e.hp=hp_max
 e.dhp=hp_max
 e.pal={11,15}
 e.shade=true
 e.wfr=0
 e.jump=true
 e.col=true
 e.pdr=draw_head
end


-- ents
function mke(fr,x,y)
 e={ fr=fr,x=x,y=y,
  vx=0,vy=0,frict=1,
  we=0,flp=false,size=8,
  ox=x,oy=y,fdx=0,fdy=0,
  recx=true,vis=true,t=0,
  gmo=gmo,
  }
 add(ents,e)
 return e
end

function upe(e)
 if e.gmo!= gmo then return end

 e.t+=1
 if e.upd then e.upd(e) end
 
 -- phys / col
 e.ox=e.x
 e.oy=e.y 
 e.vx*=e.frict
 e.vy*=e.frict
 e.vy+=e.we 

 
 if e.col then
  colphys(e)
 else
  e.x+=e.vx
  e.y+=e.vy 
 end
 
 -- recal
 if e.recx and false then
  oex=e.x
  e.x=mid( 0,e.x,arena.w*8-e.size)
  if oex!=e.x  then
   if e.impact then e.impact() end
  end
 end

 -- life
 if e.life then
  e.life-=1
  if e.blink and e.life<e.blink then
   e.vis=t%2==0
  end
  if e.life <=0 then
   kill(e)
  end
 end 
 
 -- col w opp
 if e.opp then
  opp=e.opp
  dx=abs(e.x-opp.x)
  dy=abs(e.y-opp.y)
  lim=(e.size+opp.size)*0.5
  if dx<lim and dy<lim and not opp.inv then
   hit(opp,e)
   if e.mis then
    kill(e)
   end
  end
 end
 
 -- inv
 if e.inv then
  e.inv-=1
  if e.inv==0 then
   e.inv=nil
  end
 end
 
 -- play anim
 if t%3==0 and fget(e.fr,3) then
  e.fr+=1
  if not fget(e.fr,3) then 
   while fget(e.fr-1,3) do
    e.fr-=1
   end
  end
 end
 
 -- col break
 if e.brk and chkp(e.x+4,e.y+4) then
  kill(e) 
 end
 
 -- pfr
 if e.pfr and t%2==0 then
  e.pfr+=e.pps 
  if e.pfr>=e.fmax then
   kill(e)
  end
 end
 
 -- tween
 if e.twc then
  e.twc=min(e.twc+e.spc,1)
  c=e.curve(e.twc)
  e.x=e.sx+(e.tx-e.sx)*c
  e.y=e.sy+(e.ty-e.sy)*c
  if e.twj then
   e.y+=sin(c*0.5)*e.twj
  end
  
  if e==boss then
   e.flp = e.ox>e.x
   e.fr=19
   if e.oy>e.y then
    e.fr=18
   end
  end

  if e.twc==1 then
   e.twc=nil  
   if e.twnxt then e.twnxt() end
  else
    
  end
 end
 
end

function mkp(apx,apy,sz,fmax,pps)
 e=mke(-1,0,0)
 e.fmax=fmax
 e.pfr=0
 e.pps=pps
 e.dr=function(e)  
  sspr(apx+flr(e.pfr)*sz,apy,sz,sz,e.x-sz*0.5,e.y-sz*0.5)
 end
 return e
end

function ghpo(e)
 local p={x=0,y=0}
 fr=e.fr
 for x=0,7 do
  for y=0,7 do
   pix=sget((fr%16)*8+x,flr(fr/16)*8+y)
   if pix==11 then  
    p.x=x
    p.y=y
   end
  end
 end
 p.x+=e.fdx
 if e.flp then p.x=7-p.x end  
 return p
end

function colphys(e)

 sx=sgn(e.vx)
 sy=sgn(e.vy)
 
 
 stx=abs(flr(e.vx))
 dtx=e.vx/stx 
 for i=1,stx do
  if e.dead then break end
  if chk_col(e,dtx,0) then
   e.vx=0
   if e.impact then 
    e.impact() 
    break
   end
  else
   e.x+=dtx
  end  
  if e.tcol then e.tcol(e) end
 end
 
 sty=abs(flr(e.vy))
 dty=e.vy/sty 
 for i=1,sty do
  if e.dead then break end
  if chk_col(e,0,dty) then   
   if e.jump and e.vy>0 then
    e.jump=false
    if e==hero then
     sfx(12)
    end
   end  
   e.vy=0
   if e.impact then e.impact() end
  else
   e.y+=dty
  end  
  if e.tcol then e.tcol(e) end
  
 end
 

end


function kill(e)
 del(ents,e)
 e.dead=true
 if e.ondeath then e.ondeath() end
end

function hit(e,from)
 dmg=from.dmg
 if from.hid and mget(64+from.hid-33,25)==e.hid then
  dmg*=2
 end
 e.hp-=dmg
 e.inv=24

 if hero.hid==37 and from.hid==37 then
  hero.hp=min(hero.hp+1,hp_max)
 end
 
 if e==hero then
  sfx(19)
 else
  sfx(20)
 end

 
 if from.hid==35 or from.cad==7 then
  e.poison=3
  if e.hid==33 then
   e.poison=6
  end
 end
 
end


function apal(n)
 for i=0,15 do pal(i,n) end
end

function dre(e)
 if not e.vis then return end
 
 if e.inv and t%2==0 then 
  apal(8)
 end

 if e.shade and not e.inv then
  apal(1)
  mdre(e,1,0)
  mdre(e,-1,0)
  mdre(e,0,1)
  mdre(e,0,-1)
  pal()
 end
 mdre(e,0,0)  
 pal()
 
end

function mdre(e,drx,dry)
 
 ddx=drx
 ddy=dry
 if e.pdr then e.pdr(e) end

 fdx=e.fdx
 fdy=e.fdy
 if e.flp then
  fdx*=-1
  fdy*=-1
 end
 
 x=e.x+ddx+fdx
 y=e.y+ddy+fdy
 
 fr=e.fr 

 if fr>=0 then
  spr(fr,x,y,1,1,e.flp)
 end
 if e==hero or e==boss then
  p=ghpo(e)
  pset(p.x+x,p.y+y,15)
 end
 
 if e.dr then e.dr(e) end
 
end


function chk_col(e,cdx,cdy)
 if not e.col then return false end
 if not cdx then cdx=0 end
 if not cdy then cdy=0 end
 sz=e.size-1
 dwn=e.vy>=0
 fly=e.fly
 if sz == 0 then 
  return chkp(e.x+cdx,e.y+cdy)
 end
 
 return 
  (not dwn and chkp(e.x+cdx,e.y+cdy)) or 
  (not dwn and chkp(e.x+cdx+sz,e.y+cdy)) or 
 	chkp(e.x+cdx,e.y+cdy+sz) or 
 	chkp(e.x+cdx+sz,e.y+cdy+sz) 
end

function chkp(x,y) 
 px=flr(x/8)
 py=flr(y/8) 
 
 if (px<0 or px>=arena.w) then return true end
 if py<0 or py>=arena.h then return false end
 
 
 tile=mget(px+arena.x,py+arena.y)
 if fly then 
  return fget(tile,0)
 end
 dwn = dwn and flr((y-1.5)/8)!=py 
 return fget(tile,0) or (dwn and fget(tile,2))
end

-- boss
function mk_boss(fr,x,y)
	boss=mke(16,x,y)
	boss.flp=true
	boss.hid=fr
 boss.seq={1,1,1,2,3}
 boss.sqi=-1
 boss.opp=hero
 boss.dmg=4
 init_human(boss)
 boss.upd=upd_boss
 
 
 if fr==33 then
  boss.seq={4,5,6,6,6}
 end
 
 if fr==34 then
  boss.seq={4,2,7,8,7}
 end
 
 if fr==35 then
  boss.seq={4,9,10,11,4,9}
 end
 
 if fr==36 then
  boss.seq={6,9,6,9,6,12,5,5,10,13,9}
 end
 
 
 if test_seq then
  boss.seq=test_seq
 end
 bnext()
 
end


function bnext()
 boss.sqi=(boss.sqi+1)%#boss.seq
 bplay(boss.seq[1+boss.sqi])
end

function bplay(ev)

 b=boss
 b.fdx=0
 b.wings=false
 -- skel hand
 if ev==1 then
  bshow(skel_hand) 
 end
 
 if ev==2 then
  if b.hid==34 then
   b.vy=-1
  end
  b.fr=26
  b.wings=true
  b.jump=true
  function fly_up(e)
   b.vy-=0.1
   if b.y<-32 then
    b.vy=0
    bnext()
    kill(e)
   end
  end
  loop(fly_up) 
 end
 
 if ev==3 then
  b.wings=true
  b.frict=0.93
  loop(fly_around)
 end
 
 -- run
 if ev==4 then
  loop(run_around)
 end
 
 -- show
 if ev==5 then
 
  bshow(bnext)
 end
 
 -- tomawak
 if ev==6 then
  b.fr=16
  face_hero()
  shoot_tom(b,hero)
  sfx(6)
  dl(32,bnext)
 end
 
 -- fly_random
 if ev==7 then
  b.wings=true
  b.frict=0.93
  dl(120,bnext,fly_random)
 end
 
 -- deathers
 if ev==8 then
  b.fr=29
 
  function pop()
   b.vx*=0.85
   face_hero()
   p=mkp(16,0,3,5,0.5)
   an=rnd()
   impulse(p,an,2)
   p.frict=0.95
   p.x=b.x+4-cos(an)*24
   p.y=b.y+1-sin(an)*24
  end
  
  for i=1,20 do dl(i,pop) end
  
  function go()
   b.wings=true
   b.fr=26
   sfx(6)
   for i=0,15 do 
    shoot_tom(b,hero,i/16)
   end
  end  
  dl(32,go)
  dl(64,bnext)  
 end 
 
 if ev==9 then
  b.vx=0
  b.vy=0  
  wp=wps[1+rand(#wps)]
  tw(boss,wp.x,wp.y,-3,24,bnext)
  sfx(3)
 end

 -- jump_boom
 if ev==10 then
  sfx(3)
  face_hero()
  function f()
   sfx(22)
   shake=4
   b.fr=16
   bnext()
  end 
  tw(b,b.x,b.y,16,8,f)
 end 
 
 -- spawn snake
 if ev==11 then
  for i=0,2 do
   sn=mke(6,rnd(arena.w-1)*8,-8)
   sn.upd=upd_snake
   sn.jump=true
   sn.shade=true
   sn.opp=hero
   sn.dmg=0
   sn.mis=true
   sn.cad=7
   add(monsters,sn)
  end
  dl(32,bnext)
 end
 
 -- target blocks
 if ev==12 then
  a={}
  blocks={}
  for x=0,23 do
   for y=0,7 do
    fr=mget(arena.x+x,arena.y+y)
    if fr==136 then 
     add(a,{x=x,y=y})
     break
    end
    if fr==155 then
     break
    end
   end
  end
  for i=0,2 do
   bl=pick(a)
   if bl then
    add(blocks,bl)
   else
    break
   end
  end
  bnext()  
 end
 
 -- burstb lock
 if ev==13 then
  sfx(7)
  for bl in all(blocks) do
   mset(arena.x+bl.x,arena.y+bl.y,156)
  	for i=1,3 do
  	 x=(bl.x+rnd())*8
  	 y=(bl.y+rnd())*8
  	 p=mke(141+rand(3),x,y)
  	 impulse(p,rnd(),rnd()*2)
  	 p.frict=0.95
  	 p.life=20+rand(20)
  	 p.vy-=3
  	 p.we=0.2*i  	 
  	end
  end
  blocks={}
  dl(10,bnext)
 end

end



function pick(a)
 local n=a[rand(#a)]
 del(a,n)
 return n
end

function upd_snake(e)

 dwn=true
 if e.jump then  
  if chkp(e.x+4,e.y+8) then   
   e.jump=false
   e.fr=8
   e.sens=sgn(96-e.x)
   e.flp=e.sens==-1
  else  
   e.y+=1
  end
 else 
  e.x+=0.5*e.sens
  if not chkp(e.x+4,e.y+9) then
   e.jump=true
  end 
  if e.x<-8 or e.x>arena.w*8 then
   destroy(e)
  end
  
 end
 
end

function fly_random(e)
 tx=60+cos((e.t+t)/280)*40
 ty=cos(e.t/40)*64-32  
 follow(b,tx,ty,0.01,0.2)
end


function run_around(e)
 lim=240
 acc=60
 max_spd=1.5
 
 if b.hid==35 then
  lim=60
  acc=15
 end
 
	if b.hid==33 then 
	 max_spd=3
	end
	
 kk=e.t  
 if e.t>lim-acc then 
  kk=lim-e.t 
 end
	
	spd=min(1+kk/acc,max_spd)
	
 if e.t%50==1 then
  bdir=sgn(hero.x-b.x)*1
 end  
 
 if bdir>0 and b.x>=arena.w*8-9 then
  bdir*=-1   
 end
 
 if bdir<0 and b.x<=1 then
  bdir*=-1
 end 
   
 move(b,bdir,spd)  
 hdy= b.y-8-hero.y
 chance=max(1,60-hdy)
 if hdy>0 and not b.jump and rand(chance)==0 and e.t>40 then
  b.vy=-4
  b.jump=true
  sfx(3)
 end  
  
 if (e.t>=lim and not b.jump) or b.y>arena.h*8 then
  kill(e)
  bnext()
 else
  if b.hid==34 and not b.jump and rand(60)==0 then
		 kill(e)
		 bplay(8)		  
	 end
 end 
  
end


function fly_around(e)
 
 if e.t<120 then
  tx=hero.x+cos(t/60)*24
  follow(b,tx,sin(t/40)*32-32,0.01,0.2)   
 elseif b.jump then
  b.wings=nil
  b.fr=27
  b.vx*=0.5
  b.vy+=2
 else
  kill(e)
  shake=8
  sfx(22)
  dl(40,bnext)
 end 

end


function loop(f)
 e=mke(-1,0,0)
 e.upd=f
end

function bshow(nxt)
 sfx(16)
 function f()
  face_hero()
  b.fdx=2
  b.vx*=0.5
 	b.fr=24+tmod(2,4)
 end
 
 dl(40,nxt,f)
end

function skel_hand()
 	
 hx=flr(hero.x/8)*8
 hy=hero.y
 while not chkp(hx,hy) do
 	hy+=1
 end
 hand=mke(107,hx,hy)
 hand.by=hy
 hand.opp=hero
 hand.dmg=2
	
 	
 tw(hand,hx,hy,40)
 hand.twj=8
 hand.twnxt=function()
  kill(hand)
  bnext()
 end
 	

end

function ending()
 t=0
 mupd=nil
 mdr=function()
  col=sget(min(8+flr(t/12),23),7)
  rectfill(0,0,128,128,col)
  print("congratulations",32,flr(60.5+cos(t/80)*8),1)
 
 end

end


function enter_tipi()

 if tipi.n==5 then
  fade()

  dl(20,ending)
  return
 end

 sfx(5)
 set_arena(tipi.n+1)
 tipi=nil
end


function bnext_old(bw)
 bwait=nil
 bt=0
 if bw then 
  bwait=bw 
 else
  boss.wings=false
  if fbst then
   fbst=nil
  else    
   boss.sqi=(boss.sqi+1)%#boss.seq
  end  
 end 
end

function face_hero()
 boss.flp = hero.x-boss.x<0
end

function upd_boss(b)
 upd_human(b)
end

function tw(e,tx,ty,n,twj,nxt)
 e.sx=e.x
 e.sy=e.y
 e.tx=tx
 e.ty=ty
 e.twc=0
 e.twj=twj
 e.spc=1/n
 if n<0 then
  local dx=tx-e.x
  local dy=ty-e.y
  local dd=sqrt(dx*dx+dy*dy)
  if twj then dd+=twj*1.4 end
  e.spc=-n/dd
 end
 e.twnxt=nxt
 e.curve=function(n) return n end
end

function shoot_tom(b,opp,an)
 
 dx=opp.x-b.x
 dy=opp.y-b.y
 tan=atan2(dx,dy)
  
 spd=1
 e=mke(-1,b.x,b.y)
 e.dmg=1
 e.brk=true
 if b.hid==33 then
  an=tan
  e.fr=58
  e.dmg=2
 end
 
 if b.hid==34 then
  e.fr=176+flr(an*16)
  e.frict=1.05
 end
 
 if b.hid==36 then
  e.fr=157
  e.dmg=2
  spd=0.5
  an=tan
  e.brk=false
 end
 
 impulse(e,an,spd)
 e.opp=hero
 e.life=256
 e.dmg=2
 e.hid=b.hid
 e.mis=true
 e.shade=true
 e.opp=opp
 
 
end

function impulse(e,an,spd)
 e.vx=cos(an)*spd
 e.vy=sin(an)*spd
end


function rand(n)
 return flr(rnd(n))
end

function follow(e,tx,ty,c,lim)
 dx=tx-e.x
 dy=ty-e.y
 e.vx+=mid(-lim,dx*c,lim)
 e.vy+=mid(-lim,dy*c,lim)
end



function dl(t,f,lp)
 e=mke(-1,0,0)
 e.life=t
 e.upd=lp
 e.ondeath=f
 return e
end 

function tmod(n,k)
 return flr((t%(n*k))/k)
end

function move(e,n,spd)

 e.fr=16
 e.vx=n*spd
 if n!=0 then e.flp=n<0 end
 
 if e.jump then
  e.vy += 0.25 
  e.fr=18
  if e.vy>0 then
   e.fr=19
  end 
 
 else 
  if n!= 0 then   
 	 sns=1
   if not e.flp and n==-1 then sns*=-1 end
   if e.flp and  n==1 then sns*=-1 end
   e.wfr=(e.wfr+spd*sns/4)%8
   e.fr = 16+flr(e.wfr)
   
   if t%8==0 then
    
    sfx(13+flr((t%8)/4))
   end
   
   if not chk_col(e,0,1) then
    e.jump=true
   end
  end    
 end
end

--
function upd_human(e)

 if e.poison and t%100==0 then 
  e.poison-=1
  e.hp-=1
  sfx(18)
  function bub()
   p=mkp(32,0,4,4,0.5)
   p.x=e.x+rand(8)
   p.y=e.y-2
   p.we=-0.1
   p.life=32
  end  
  for i=0,3 do
   dl(i*4,bub)
  end
  
  if e.poison==0 then e.poison=nil end
 end
 
 if e.hp!=e.dhp then
  e.dhp+=sgn(e.hp-e.dhp)
 end 
 
end
 
--

 
-- hero
function upd_hero(h)
 if fading then return end
 upd_human(h)
 
 -- enter tipi
 if btn(2) and arena.bg==0 then
  if tipi and pwr then   
   if tipi.ok then
    enter_tipi()
    return
   else
    if tipi.n<5 then
     refill+=1
     if refill==refill_max then
      tipi.ok=true
      add(spirits,tipi.n+33)
      pwr=false
     end
    end
   end
  end
 else
  pwr=true
  refill=0
 end

 --move
 h.vx=0
 spd=2
 if h.hid==33 then spd=3 end
 if focus then spd=1 end
 n=0
 if btn(0) then n=-1 end
 if btn(1) then n=1 end
 move(h,n,spd) 

 -- check jump
 if not h.jump and djp then
  djp=false
 end
 if ( not h.jump or (djp and h.vy>=-1) ) and btnp(4) then
  if djp then
   sfx(4)
   djp=false
   for i=1,3 do
    p=mke(184,h.x+4,h.y+8)
    p.life=50
    p.we=0.1
    p.vy=-1-rnd()*2
    p.vx=rnd(4)-2+h.vx*0.5
    p.t=rand(128)
    p.upd = function(e)
  			fr=flr(188+cos(e.t/20)*6)
     e.fr=mid(184,fr,191)    
    end
    p.blink=20
    p.frict=0.95
    p.shade=true
   end
   
  else
   sfx(3)
   djp=h.hid==34
  end
  
  h.jump=true
  h.vy=-4
  
 end
 
 -- bow
 if focus then 
 
  function inc(n)
   h.ady= mid(-10,h.ady+n,10)
  end
  if btn(2) then inc(-1) end
  if btn(3) then inc(1) end
    
  if btn(5) then
  	focus=min(focus+1,focus_max)		
  else
  	shoot()
  	focus=nil
  	bowbk=4
  end
 else
  if btn(5) then
   focus=0
   h.ady=0
  end
 end
 
 -- shapeshift
 if btnp(3) and not focus then
  
  secure_swap(1)
  sfx(15)
  function pop()
   p=mkp(8,0,3,4,0.1+rnd(0.5))
   p.x=h.x+4+rand(8)-4 
   p.y=h.y+rand(8)-4
   p.frict=0.95
   p.vx=h.vx
   p.vy=h.vy
   p.we=-0.1
  end
  
  for i=0,8 do
   pop()
   dl(i*2,pop)
  end  
 end
 
 -- tipis
 ot=tipi
 tipi=nil

 for tp in atipis() do
  adx=abs(tp.x*8+4-h.x)
  ady=abs(tp.y*8-h.y)
  if adx<8 and ady<1 then
   tipi=tp
 
  end  
 end
 
 if ot!=tipi then
  if tipi then
   sfx(10)
  else
   sfx(11)
  end
 end
 
 
 -- fall dead
 if h.y > arena.h*8 then
  h.hp=0
 end
 
 -- quiver
 --
 if arrows==0 and not quiver then
  quiver=mke(14,0,0)
  quiver.y=-32
  quiver.x=(1+rand(arena.w-2))*8
  quiver.upd=upd_quiver
  quiver.jump=true
  quiver.shade=true  
  quiver.ondeath=function()
   quiver=nil
  end
 end
 
end

function upd_quiver(e)

 if e.jump then  
  dwn=true
  if chkp(e.x+4,e.y+8) then   
   e.jump=false
   e.life=120
   e.blink=40
  else  
   e.y+=1
  end
 else 
      
 end
 
 adx=abs(hero.x-e.x)
 ady=abs(hero.y-e.y)
 if adx<8 and ady<8 then
  sfx(21)
  kill(e)
  arrows=arrows_max
 end
 
end

function secure_swap(n)
 swap(n)

 while boss and hero.hid==boss.hid do
  swap(1)
 end
end
function swap(n)
 shid=(shid+n)%#spirits
 hero.hid=spirits[1+shid]
end

function atipis()
 if arena.bg>0 then return all({}) end
 return all(tipis)
end

function shoot()
 
 if focus <=1 or arrows==0 then 
  return 
 end
 
 sfx(1)
 refill=0
 if arena.bg>0 then 
  arrows-=1
 end
 local e=mke(-1,hero.x+4,hero.y+2)
 e.hid=hero.hid
 e.dmg=1
 e.col=true
 e.shade=true
 e.we=0.3--0.2
 e.size=1
 e.an=gaa(1)+0.5
 impulse(e,e.an,1+focus/2)

 e.ox=e.x-cos(e.an)*4
 e.oy=e.y-sin(e.an)*4
 e.x+=e.vx
 e.life=512
 
 e.tcol=ar_col
 e.blink=40
 e.dr=drar
 e.upd=upd_arrow
 e.fly=true
 
 e.impact=function()
  e.vx=0
  e.vy=0
  e.we=0
  e.col=false
  e.life=120
  e.grab=true
  e.fly=false
  e.impact=nil
  e.tcol=nil
  sfx(2)
 end
 
end

function drar(e)

 dx=cos(e.an)
 dy=sin(e.an)
 if e.bdy and e.flp!=boss.flp then
  dx*=-1
 end  
 local x=e.x+ddx
 local y=e.y+ddy
 sspr(8+(e.hid-32)*3,3,3,3,x+dx*7-1,y+dy*7-1)
 if not e.bdy then
  line(x,y,x+dx*2,y+dy*2,7)
 end
 x+=dx*2
 y+=dy*2
 line(x,y,x+dx*6,y+dy*6,4)
 
 if e.cad then
  spr(e.cad,x+dx*4-4,y+dy*4-4)
 end
 
end

function upd_arrow(e)

 -- fly
 if e.fly then
  dx=e.ox-e.x
  dy=e.oy-e.y
  e.an=atan2(dx,dy)
 end
 
 -- grab
 if e.grab then
  px=e.x+cos(e.an)*4
  py=e.y+sin(e.an)*4
  adx=abs(hero.x+4-px)
  ady=abs(hero.y+4-py)
  if adx<8 and ady<8 then
   sfx(17)
   arrows+=1
   kill(e)
  end 
 end
 
 -- boss 
 if e.bdy then
  p=ghpo(boss)
  e.x=boss.x+p.x+4-3
  e.y=boss.y+e.bdy+p.y
 

 end
 
end



function show_pix(x,y)
 p={x=x,y=y,col=7}
 add(pixels,p)
end

function ar_col(e)
 if not boss then return end
 
 adx=abs(boss.x+4-e.x)
 ady=abs(boss.y-e.y)
 if adx<4 and ady<7 then 
  hit(boss,e)
  e.impact(e)
  e.bdy=e.y-boss.y
  e.flp=boss.flp
  e.vis=boss.hp>0
 end
 
 for m in all(monsters) do
  adx=abs(m.x+4-e.x)
  ady=abs(m.y+4-e.y)  
  if adx<4 and ady<4 then 
   e.cad=m.cad
   e.vx*=0.75
   e.vy*=0.75
   --kill(e)
   destroy(m)
  end  
 end
 
end

function destroy(m)
 del(monsters,m)
 kill(m)
 
end

function get_dmg(hid)
 dmg=1
 return dmg
end




function draw_head(h)

 p=ghpo(h)
  
 p.x+=h.x+ddx-3
 p.y+=h.y+ddy-8

 function ghx(n)
  local sns=1
  local k=0
  if h.flp then 
   sns=-1 
   k=1
  end
  return p.x+n*sns-k
 end
 
 -- draw bow
 if h.hero then 
 if focus then 
  ac=4
  c=(focus-ac)/(focus_max-ac)
  c=max(c,0)
  cc=min(focus/ac,1)
  ac*=cc
  px=ghx(ac+6-(1-cc)*4-c*5)
  
  if arrows>0 then
   draim(h,ac+6-(1-cc)*4-c*5)
  else

  c=0
  end
  px=ghx(ac)
  spr(48+c*3,px,p.y+5+(h.ady/4),1,1,h.flp)

 elseif bowbk then
  bowbk-=0.2
  px=ghx(bowbk)
  spr(48,px,p.y+5,1,1,h.flp)
  if bowbk<=-1 then bowbk=nil end
 end
 end
 -- draw head
	px=ghx(1)
 spr(h.hid,px,p.y,1,1,h.flp) 
 
 -- draw wing
 if h.wings then
 	fr=53+tmod(3,2)
 	if bst==8 then fr=53 end
 	spr(fr,p.x-8,p.y+4,1,1,false)
 	spr(fr,p.x+7,p.y+4,1,1,true)
 end
 
end

function draim(h,dd)
 local an=gaa(0)
 dd+=4
 e={
  hid=hero.hid,
  an=an,
  x=h.x+4-cos(an)*dd,
  y=h.y+1-sin(an)*dd,
 }

 drar(e)
end

function gaa(dy)
 local sns=-1 
 if hero.flp then sns=1 end
 return atan2(sns*8,dy-hero.ady)
end

function explode(e)
 sfx(7)
 sfx(8)
 gmo=1
 kill(e)
 cex=e.x
 cey=e.y
  
 for i=0,15 do 
  an=i/16
  p=mke(173,cex,cey)
  impulse(p,an,3)
  p.life=60
  for k=0,2 do 
   p=mkp(8,0,3,4,0.1+rnd(0.25))
   impulse(p,an+rnd(i/16),3)
   p.frict=0.85+rnd(0.14)
   p.x=cex+4
   p.y=cey+4
  end
 end
 
 if boss.dead then
  tipis[boss.hid-32].ok=false
  del(spirits,boss.hid)
  tipis[6].ok=#spirits==1
 end
 dl(40,fade)
  
end

function fade(enter)
 fading=true
  hero.vx=0
  hero.vy=0
 if gmo and not enter then
  sfx(9)
 end

 local px=64
 local py=0
 function f(e)
  for x=0,15 do
   for y=0,15 do
    an=(atan2(x-8,y-8)-0.25)%1
   	k=an*5+e.t*0.5
			 fr=flr(110+k)
			 if enter then
			  fr=flr(126-k)
			 end
    fr=mid(116,fr,120)
    if fr==116 then 
     fr=0
    end
    mset(px+x,py+y,fr)
   end
  end
 end 
 function nxt()
  fading=false
  if gmo then
   restart()
  end
 end 
 
 d=dl(24,nxt,f)
 d.upd(d)
end

function restart()
 from=boss.hid-33
 reset()
 set_arena(0)

end





function _update()
 msg_a=nil
 msg_b=nil
 t+=1
	if mupd then mupd() end
  
end




function _draw()
 cls() 
 
 if mdr then mdr() end
 
 -- log 
 cursor(0,0)
 color(8+(t%8)) 
 color(8) 
 for l in all(logs) do
  print(l)
 end
end

function draw_spirits()
 if arena.bg!=0 then return end
 ec=20
 x=(128-((#spirits-1)*ec))*0.5
 k=0
 for sp in all(spirits) do
  k+=1
  by=flr(12.5+cos((t+k*8)/40)*4)
 
  function f() return rand(3)-1 end
  for i=0,2 do
   col=sget(24+i,6)
   circfill(x+f(),by+f(),7,col)
  end
  spr(sp,x-4,by-4)
  x+=ec
 end
end

function place_cam()
 roof=-128
 if arena.roof then 
  roof=min(arena.h-16,0)*8
 end
 cx=mid(0,hero.x-64,(arena.w-16)*8)
 cy=min(hero.y-64,(arena.h-16)*8)
 cy=max(roof,cy)
 if shake then  
  cy+=shake
  shake*=-0.75
  if abs(shake)<1 then 
   shake=nil 
  end  
 end 
 camera(cx,cy)
end

function log(str)
 add(logs,str)
 while #logs>20 do
  del(logs,logs[1])
 end
end

function dr_game()
sspr(8*arena.bg,64,8,8,0,0,128,128)
 
 -- camera
	place_cam()
 
 -- map under
 map(arena.x,arena.y,0,0,arena.w,arena.h) 
  
 -- tipis
 for tp in atipis() do
  if not tp.ok then
   for i=0,1 do
    fr=87-i*16
    if tp.n==5 then
     fr+=1
    end
    spr(fr,(tp.x+i)*8,tp.y*8)
   end
  end
 end
 
 -- ents
 foreach(ents,dre)
 
 -- refill
 c=1-refill/refill_max
 if c<1 then
  circ(hero.x+4,hero.y+4,c*64,7)
 end
 -- map above
 map(arena.x,arena.y,0,0,arena.w,arena.h,2) 
 
 -- blocks
 if t%4<2 then
  for bl in all(blocks) do
   spr(140,bl.x*8,bl.y*8)
  end
 end
 
 -- sel tipi
 c=flr(cos(t/32)*4+0.5)
 if tipi then
  fr=33+tipi.n
  msg_a="will you free"
  msg_b=names[tipi.n+1].." ?"
  if tipi.ok then
   fr=12
   msg_a="fight the"
   msg_b=names[tipi.n+1].." spirit"   
  end
  
  if tipi.n==5 then
   if tipi.ok then
    msg_a="you can rest"
    msg_b="for now"
   else
    msg_a="too many"
    msg_b="spirits here"
   end
  else
   for i=0,1 do 
    if i==0 then apal(1) end
    spr(fr,tipi.x*8+4-i,tipi.y*8+c-16-i)
    pal()
   end
  end
 

  
 end
 
 -- debug
 for p in all(pixels) do
  pset(p.x,p.y,8+(t%8))
 end
 pixels={}
 
 camera()
 -- inter
 if boss then
  a={hero,boss}
  for i=0,1 do
   e=a[1+i]
   py=9
   px=2+i*116
   spr(e.hid,px,1,1,1,i==1)   
   palt(14,true)
   palt(0,false)  
  	function f(n,flp)
   	sspr(0,72+n*2,8,2,px,py,8,2,false,flp)
    py+=2
   end
   f(0)
   for k=0,hp_max-1 do
    n=2+i
    if k<hp_max-e.dhp then 
     n=1 
    else
     if e.poison and k-e.poison<hp_max-e.dhp then n=4 end
    end    
    f(n)
   end
   f(0,true)
   palt()
  end
    
  for i=0,arrows_max-1 do
   if i==arrows then 
    apal(1)
   end
   spr(52,11,9+i*4-2)
  end
  pal()
  c=1-refill/refill_max
  if c<1 then
   rectfill(0,9+40*c,0,49,7)
  end
 end
 
 -- msg
 if msg_a then
  my=92
  apal(5)  
  ec =flr(2.5+cos(t/40)*2)
  dy=-ec/2
  map(16,24,32+ec,my+ec,8,4)
  pal()
  map(16,24,32,my+dy,8,4)  
  function prn(str,y)
   x=(128-#str*4)/2
   print(str,x,y+dy)
  end
  prn(msg_a,my+8)
  prn(msg_b,my+16)
 end
 
 -- spirits
 draw_spirits()
 
 -- fade
 if fading then
  map(64,0,0,0,16,16)
 end
 
end

names={"horse","eagle","snake","rabbit","vulture","secret"}
__gfx__
82800000c7c0c0000000000d0d7d0000000000003bb3007000090000000000000000000000000000000000000000000000bbbb0000000000b4b0000000000000
22200000777ccc0c0d0070d7d777000003000b30b70b700000040000000000000000000000000000000000000000000000bbbb00049999944b40000000000000
82800000c7c0c0000000000d0d7d000000000330b00b0007000b0000000000000000000000000000000000000000000000bbbb0001121211b404400000000000
453100008289497d7b3bd1dfef000000000000003bb3070000b00bb0000b3bb0900000bb00000bb00000000000000000bbbbbbbb041919140044940000000000
7dd10000222444ddd333111eee000000000000000000000000b00bb000b00bb4503b30bb03b303bb3b303b309503b3000bbbbbb0041919140054494000000000
b35100008289497d7b3bd1dfef0000000000000000000000003000300080003090b0b0b00b0b03bb90b0b030090b0bbb00bbbb00012929210005449400000000
ed000000128b8477ea7a6ef7e8200000000000000000000000b303b0008303b0b0b0b0b0090b0b0050b0b0bb0b0b03bb000bb000012424210000544400000000
510000001112244499aaaaaa000000000000000000000000000b3b00000b8b003b303b309503b300903b30bb03b3033000000000099999940000055400000000
0000000000000000004bff000004bff0000000000000000000fb4400000fb4400000ffff00000000fffbff4f0000000000000007077b4d700000000000000000
004bf40004bf40000044fff000544fff004bf40004bf400000ff440000fff4454bffff404bffffffffffff54ff000044004bf404777744d70000000000000000
004ff40004ff400005444fff045444ff004ff40004ff40000ff444500fff44454fff00004fffff400054ff00fffb4444004fff04777744d70000000000000000
00ff440004ff4000054444ff0454444000ff44000ff440000ff444500ff44440444400004444000000444f000ffff4540044ffff777774d70000000000000000
00fff800044ff0000f8888540ff8888000fff8000ff44000048888ff045888808888000088880000008888000054440000888fff76767d770000000000000000
008ff800088ff000fff885440fff8854008ff8000ff8800044588fff044588ff888800008888000000488f004044440f00888804767677700000000000000000
00ff4000fff55000f00000000000004400ff4000455ff00040000000000000ffff400000ff4000000044ff00448888ff00ff400406d6d6000000000000000000
00fff400ff044400000000000000000000fff400440fff000000000000000000fff40000fff400000004f000448888ff00fff400006d6d000000000000000000
070000000240000000000000000bbb0000dd0000000fff00000000000000000000000000000000000000000000e0000000000000000000000000000000000000
0700000004200000000000000bbbb7b000df000000ffffa00b3b0700000000000055000000000000000000000eee000000000000000000000000000000000000
007000000447400000000000b333bbb000df0000044f5faa3bbbd70000d060000555500000000000000000000e2e000000000000000000000000000000000000
007555000475744000677600b330000e00df0000400fff99bbb3700000dd60005555500000000000049994002eeee20000000000000000000000000000000000
008888000447445506775700b330000000ddd000f00000093bb3330000ddd600555555000000000049999940eee2ee0000000000000000000000000000000000
0055ff000444445507777790b330000000dddd50ff40000013bb370700d1dd60155557000000000049949590eee2ee2e00000000000000000000000000000000
004fff0004244455666666990bb300000ddddd700fff00003133333d0dddddd1111555100000000049949595eeeeee2e00000000000000000000000000000000
004440000442200006d6d6000bb300000ddd100004ff0000111333300ddddddd1115511000000000244299992eeeee0000000000000000000000000000000000
000040000000400000004000000040000000000000777000000000000000000000077000000c7c00000666000044400000000400004400000004000000000000
000074000000740000007400000704000000000007676700000000000000000007d77d7000c777c0000006600444400000000040064466000064560000000000
0000704000070040000700400070004000000000666d767000000000000000000d7777d00cc71c77000004444004400006600044664466000064560000000000
00007040000700400070004007000040b3b00000d6d6d760000000000000000077777777c7c77c77444444440000400606600444600400000004000000000000
000070400007004000700040070000404444447d006d6d7707676777767677777777777770000007444006600000400644444444600400000004000000000000
00007040000700400007004000700040b3b000000006d67700777777776767770d7777d0c0000000440006600066446644400000000440040004000000000000
000074000000740000007400000704000000000000000000000000000777777007d77d7007c00000040000000066446006600000000444400004000000000000
00004000000040000000400000004000000000000000000000000000007777000007700000000000004000000000440000666000000444000004000000000000
49445499944554999444494500000005544555550000000f900000009999999999889999dddd1ddddddddddd111ddddd99499994009499949949999449999400
99444999994459999944999400000005994454450000000f900000009499999998889999dddddddddd776ddd11dddddd44544445094544454454444554444540
9944499999445999994499940000005599445445000000ff9900000099999999888499996ddddddddd7716dd1ddd6ddd44455454945555555555555555549954
54445499944494999449944500000555544455550000009f940000009499999988449999d1ddd6dddd6167ddddd61ddd55455555455555555499455555554455
055554445549944455499450000055555555555500000fff999000009999999988499999dddddd1ddd1671ddddd1dddd45554544455555555544555544455555
000004449994444499444500045055555554455500000f9f949000009499999988899999ddddddddddd11ddddddddddd44455554555444555555555555555555
00000544999445449945500005555555555445550000ffff999900009999999948889999dddddddddddddddddddddddd55554455555555555555544555555445
00000055444455554400000055555555555555550000ff9f949900009499999994889999ddd6dddddddddddddddddddd54454444555555555555555555555555
5549994555555555555555555555555555000000000fffff99999000ffffffffffff88ff00000000dddd1dddddd1111155555555559499944999945500b33300
4449944455555555005555555555555555000000000fff9f94999000ffffff9fffff888f00000011ddddd6dddddd111155555555594544455444454507b33300
994444495555055000000555555555555554400000ffffff99999900ffffffffffff9888000011116dddd66ddddddd1155555555945555445555555400b33360
945444495550000000000055555555555555440000ffff9f94999900ffffff9ffffff98800001111d1dd611dddddddd155555555455555554994555500b33300
44559949555500000000055555555555555555000fffffff99999990ffffffffffffff8800111111dd661d6ddddddddd55555555455445555445555500b36300
99994944555500000000055555555555555550000fffff9f94999990ffffff9ffffff88800116161dd16ddd1dddd6ddd55555555455555555555555500b33300
4994459955500000000000555555555555555550ffffffff99999999ffffffffffff88891116666dddd1dddd6dddd1dd55555555455555555555445507b33300
4444554455000000000000055555555555555555ffffff9f94999999ffffff9fffff889f1116d16dddd6ddddd1dddddd55555555455555445555555500b33360
050000000000000000000000ccccccccccccccccfffffff119999999000000000000000000000000000000010707070000b333000073330000b33300000bb000
050005000000000000000000ccccccccccccccccfffff9f1194999990000000000000000110000000000001100d0d0d007b3330000b336000033330000bb3300
505050000000000000000000ccccccccccccccccffffff111199999900000500005000001111000000001111000d0d0d00b63333333333333333336000b33360
000500500000000000000000cccccccccccccccdffff9f111194999900000500005000001111000000011111700d0d0d00333363333333363363330000b33300
500555000000000000000000ccccccccccccccddfffff11111199999000005500550000011111100001111110dd7777000033333336333333333300000b36300
055500500000000009450000cccccccccccddcddfff9f11551194999000000500500000011111100001111110077d77000003333333333333333000000b33300
505500000099400094455000cccccccccccdddddffff1155551199990000005555000000111111110111111100777dd00000006000b333000600000007b33300
005550000044450044555000ccccccccccddddddff9f1555555194990000000550000000d6d6d11111111111000ddd000000000000b333600000000000b33360
0000000000000000cccccddd77007700ddddcddd0000000000000000001111001111111111111111100000001d17776d67777d77677d67710000000000000000
0000000000000000ccdddddddc77dc77dddddddd000000000001100001111110111111111111111111000000011d6611dd77d1ddddd1ddd10000000000000000
0000000000000000cdddddddccccccccdddddddd00000000001111001111111111111111111111111110d0000001dd6dd1dd161dddd111000000000000000000
0000000000000000ddddd4ddccccccccddddd4dd0001100001111110111111111111111111111d111111dd00000011dd16d16dd1dd1d10000000000000000000
0000000000000000ddddd444cccccccc444dd444000110000111111011111111111111111111dd11111d10000001d1111dd11dd1111110000000000000000000
0000000000000000ddd44444ccccccccddd4444400000000001111001111111111111111111111dd111111000001111101111111011100000000000000000000
0000000000000000ddd44544ccccccccddd4454400000000000110000111111011111111111111d1111111110000110000001110000000000000000000000000
0000000000000000dd445555cccccccc444455550000000000000000001111001111111111111111111111110000000000000000000000000000000000000000
22222222cccccccc7777777711111111222222220000000000000000000000002211122111111111021111110011222100011000000000000000000000000000
22222222cccccccc66666666cccccccc222222220000000000000000000000008811222211111120022112111212222200177100000000000000000001111000
44444444cccccccccccccccccccccccc222222220000000000000000000000001118822811212100000112112222222201777710000000000001100001211100
44444444cccccccccccccccccccccccc222222220000000000000000000000001228988811208200000218218828222201777710000210000022210002222220
99999999ddddddddcccccccccccccccc222222220000000000000000000011112222999111000800000021111118888800177100000820000082220002222880
99999999eeeeeeeecccccccccccccccc888888880000000000000000000111128222111112000000000082011111998100011000000000000009800000889900
aaaaaaaaffffffffcccccccccccccccc999999990000000000000000000211229888222110000000000000011111111100177100000000000000000000099000
77777777ffffffffdddddddd11111111aaaaaaaa0000000000000000000288829998128220000000000000021111111100011000000000000000000000000000
eeeeeeeebbb33b3b1111111111111111111111111111111311111111111111110000000000000000000000002211122111111111000000000000000000000000
e777777ebb33244b111311100111111111111111111331111133111111111111000000001000000000000000881122221111122100088000008aa80000000000
70111107442214441113313331111331111111111110300103311100111111110000000011100000000000111118822811111221089aa980009aa90000000000
70000007422bb34411111000000133111111111113000033001133001111111100000000111000000000011112289888111111110aaaaaa008aaaa8000000000
79799947112442221111310000111111111111111130000000000bb01111b11100000000111110000000111122229a91111111110aaaaaa008aaaa8000000000
74944417bbb32222111033000b3100111111111111110011000000001b3133310000000011111000011011118222111111211111089aa980009aa90000000000
78f88827444221221133000000000111111111111111111100000000bb333333000000001111110001111111988822211111111100088000008aa80000000000
7282221722221111101100000000310111111111111111110000000013333331000000001111111111111111aa98128211111111000000000000000000000000
7b7bbbb7114214411330000000000003211121111112111211111113333333333111111110000000009999944999999449994200200000020000000002000020
73b33317112244223311000000000031411121111112111211131133333333333311111111200000024ff42222222222222222200000000000eeee0022200222
000000004b31222211103300001331014121111111111212111331b3333333333313bb111111222204ffff442444494424442442000ff0000eeeeee002000020
000000004221112111133100003333114241111111111222bb3133bb33333333311333b11111111102f99f22222222222222222200ffff000eeeeee0000ff000
0000000022211111131110000311111142412111111212221bb3333333333333333311111111111102f99f22222222222222222200ffff000eeeeee0000ff000
00000000111114421331333313331111424141111112122211133333333333333333bb311111111101ffff211111122111112222000ff0000eeeeee002000020
7cfcccd7111144221131331001111331414121111112121213133333333333333333331111111111014ff42222222222222222200000000000eeee0022200222
7dcddd17111122211111111111113311212111111111121133333333333333333331133311111111001111111111111111111100200000020000000002000020
000000000000000000000000000007000007000000700000000000000000000000000000000000000000000d00000d000000d00000d00000d000000000000000
00000000000000700000677000007770006760000777000007760000070000000000000000000070000007d000007d700007d70007d700000d70000007000000
076777600000777700067770000777000077700000777000077760007777000000000000000776dd00067d700006d6000006d600006d600007d76000dd677000
ddd66777006767700067776000776700007670000076770006777600077676000677767000776d70006767000007670000076700007670000076760007d67700
0767776007d67700007676000076700000767000000767000067670000776d7077766ddd07767600067776000076770000076700007767000067776000676770
00000000dd67700007d76000006d6000006d60000006d60000067d70000776dd0677767077770000077760000077700000077700000777000006777000007777
00000000070000000d70000007d70000007d700000007d70000007d0000000700000000007000000077600000777000000067600000077700000677000000070
0000000000000000d000000000d00000000d000000000d000000000d000000000000000000000000000000000070000000007000000007000000000000000000
0ff90ff00f0ff0ff0ff09ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05ff59f55f5ff5ff5f95ff5000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
055954954f4ff4ff4954955000000000000999000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000
ff4554454444f4ff454454ff00000000999900000000444444444400044444442024444444444444202244444444440044400000444000090000000000000000
9ff44444444444f444444ff900090000900000044444444444444402444444444244444444444444442444444444440044440002444000099990009009999000
05544444444444444444455000090000900000044444444444444404444444444244444444444444442444444444440444440024444400000099999009000000
05444444444444444444445000099999999999044444444444444444444444444444444444444444442444444444440444444224444400000090000009000000
9ff444444444444444444ff900000999999999044444444444444444444444444444444444444444442444422222200444444444444440999999999999999000
ffff4444444444444444445000000000000000044444444444444444444422444444444444444444442444422222200444444444444440999999999000000000
fffff4444444444444444fff00999000000000044444444444444444444222444444444444444444442444444442004444444444444440000000000000000000
05444444444444444444445000009009999990044444444444444444444222444444444444444444442444444440004444444444444440000000000000999990
ffff44444444444444444fff09999999999990002222444442222244444200444442222444442222222444444440004444444444444444009999999999909990
fff44444444444444444ffff00000000000000000222444442222244444000444442222444442222224444444440004444444444444444009999999000009990
05444444444444444444445000000000000000000000044444220044444400444442200444440000244444422220004444444444244444000000000000099900
fff4444444444444444fffff00009000099999900000044444220044444444444422200444440000244444422200044444424444244444000000000000000000
05444444444444444444ffff00009999999999999990044444220044444444444422000444440000244444444444444444224444224444000999999990000000
9f4444444444444444444ff900000090000000999990044444220044444444444422000444440000244444444444424444224442224444400999999999990900
05544444444444444444445000000099990000099990044444220024444444444222044444444400224444444444422444222200224444400999000000099900
05444444444444444444445000000000990000009990044444220004444444444222044444444400224444444444422244222200224444409990000000090000
9ff444444f44444444444ff900000009900000000990000222220000222222222220022222222200022222222222022222222000222222009900000000099990
ff554444ff4f4444444444ff00000000000000000000000002220000002222222220002222222000022222222220022220000000222200090000000000000090
05594494ff4ff4f44944955000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099990
05ff59f5ff5ff5f55f95ff5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ff90ff0ff0ff0f00ff09ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222eeeee2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
222222222ee8822222222222222222222222222222222222222222222222222222222222222222222222222222222222e2222222222222222222222222222222
22222222e88222222222222222222222222222222222222222222222222222222222222222222222222222222222222222e22222222222222222222222222222
2222222e8827222222222222222222222222222222222222222222222222222222222222222222222222222222222222222e2222222222222fff222222222222
2222222882272222222222222222222222222222222222222222222222222222222222222222222222222222222222222222e22222222222ffffa22222222222
222222e8822272222222222222222222222222222222222222222222222222222222222222222822222222222222dd2222228222222222244f5faa2222222222
22222288222275552222222222222222222222222222222222222222222222222222222222222228222222222222df2222222e22222222422fff992222222222
22222288222288882222222222222222422222222222222222228222222222222222222222222222822222222222df2222222822222222f22222292222222222
22222288222255ff2222222222222224222222222222222222822222222222222222222222222222282222222222df2222222822222222ff4222222222222222
2222228822224fff222222222222222447422222222222222822222222222222222222222bbb2222282222222222ddd2222228222222222fff22222222222222
22222288222244422222222222222224757442222822222282222222222222222222222bbbb7b222228222222222dddd5222282222222224ff22222222222222
2222222882222222222222222222222447445522282222228222222222222222222222b333bbb22222822222222ddddd72228822222222222222222222222222
222222288222222222222222222222244444552228222228222222222222222222e222b332222e2222822222222ddd1222228222222222222222222222222222
222222228822222222222222222222242444552288222228222222222222222222e222b332222222228222222222222222288222222222222222222222222222
222222222882222222222222222222244222222288222228222267762222222222e222b332222222228222222222222222882222222222222222222222222222
222222222228822222222222222222222222222882222228222677572222222222ee222bb3222222282222222282222288822222222222222222222222222222
222222222222222222222222222282222222228882222228222777779222222222ee222bb3222222282222222222888882222222222222222222222222222222
22222222222222222222222222222882222288882222222282666666992222e2222ee22222222222822222222222222222222222222222222222222222222222
2222222222222222222222222222228888888882222222228226d6d622222222222eee2222222228222222222222222222222222222222222222222222222222
2222222222222222222222222222222288888222222222222822222222222e222222eeee222228e2222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222228222222222e22222222eeeeeeeee22222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222e822222ee22222222222eeeee2222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222eeeee2222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444414444444444444444444444444444444444444444444444444444444444bb4
4444444444444444444444444444444444444444444444444444444444444444417144444444444444444444444444444444444444444444444444444444bb33
4444444444444444444444444444444444444444444444444444444444444444417144444444444444444444444444444444444444444444444444444444b333
4444444444444444444444444444444444444444444444444444444444444444441711144444444444444444444444444444444444444444444444444444b333
4444444444444444444444444444444444444444444444444444444444444444441755514444444444444444444444444444444444444444444444444444b363
4444444444444444444444444444444444444444444444444444444444444444441888811444444444444444444444444444444444444444444444444444b333
444444444444444444444444444444444444444444444444444444444444444444155ff14144444444444444444444444444444444444444444444444447b333
44444444444444444444444444444444444444444444444444444444444444444414fff71414444444444444444444444444444444444444444444444444b333
999999999999999999999999999999999999999999999999999599999999999999144478114111999999999999999999999999999999999999999bb99999b333
9999999999999999999999999999999999999999999999999995999599999999914ff44444447719999999999999999999999999999999999999bb339997b333
9999999599995999999999999999999999999999999999999959595999999999914ff42811411199999999999999999999999999999999999999b3336999b333
999999959999599999999999999999999999999999999999999995995999999991ff447191419999999999999999999999999999999999999999b3339999b333
999999955995599999999999999999999999999999999999995995559999999991fff81714199999999999999999999999999999999999999999b3639999b363
9999999959959999999999999999999999999999999999999995559959999999918ff81141999999999999999999999999999999999999999999b3339999b333
999999995555999999999999999999999999999999999999995955999999999991ff419919999999999999999999999999999999999999999997b3339997b333
999999999559999999999999999999999999999999999999999955599999999991fff41999999999999999999999999999999999999999999999b3336999b333
999999999f9999999999999999999999999999999949445499944554999445549911114945999999999999999999999999999999999999999999b33399997333
999999999f9999999999999999999999999999999999444999994459999944599999449994999999999999999999999999999999999999999997b3339999b336
99999999ff9999999999999999999999999999999999444999994459999944599999449994999999999999999999999999999999999999999999b63333333333
999999999f9499999999999999999999999999999954445499944494999444949994499445999999999999999999999999999999999999999999333363333333
9999999fff9999999999999999999999999999999995555444554994445549944455499459999999999999999999999999999999999999999999933333336333
9999999f9f9499999999999999999999999999999999999444999444449994444499444599999999999999999999999999999999999999999999993333333333
999999ffff999999999999999999999999999999999999954499944544999445449945599999999999999999999999999999999999999999999999996999b333
999999ff9f949999999999999999999999999999999999995544445555444455554499999999999999999999999999999999999999999999999999999999b333
99999fffff999999999999999999999999999999999999999955499945944449459999999999999999999999999999999999999999999999999999999999b333
99999fff9f949999999999999999999999999999999999999944499444994499949999999999999999999999999999999999999999999999999999999997b333
9999ffffff999999999999999999999999999999999999999999444449994499949999999999999999999999999999999999999999999999999999999999b333
9999ffff9f949999999999999999999999999999999999999994544449944994459999999999999999999999999999999999999999999999999999999999b333
999fffffff999999999999999999999999999999999999999944559949554994599999999999999999999999999999999999999999999999999999999999b363
999fffff9f949999999999999999999999999999999999999999994944994445999999999999999999999999999999999999999999999999999999999999b333
99ffffffff999999999999999999999999999999999999999949944599994559999999499999999999999999999999999999999999999999999999999997b333
99ffffff9f949999999999999999999999999999999999999944445544449999999944459999999999999999999999999999999999999999999999999999b333
9ffffffff11999999999999999959999999999999999999999554999455549994594455499999999999999999999999999999999999999999949445499554999
9ffffff9f11949999999999999959995999999999999999999444994444449944499445999999999999999999999999999999999999999999999444999444994
ffffffff111199999999999999595959999999999999999999994444499944444999445999999999999999999999999999999999999999999999444999994444
9fffff9f111194999994999999999599599999999999999999945444499454444994449499999999999999999999999999999999999999999954445499945444
fffffff1111119999999999999599555999999999999999999445599494455994955499444999999999999999999999999999999999999999995555444445599
9ffff9f1155119499994999999955599599999999999999999999949449999494499944444999999999999999999999999999999999999999999999444999949
ffffff11555511999999999999595599999999999999999999499445994994459999944544999999999999999999999999999999999999999999999544499445
9fff9f15555551949994999999995559999999999999999999444455444444554444445555999999999999999999999999999999999999999999999955444455
9994455499944554999445549994455499944554999445549955499945554999455549994594455499aaaaaaaaa5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
9999445999994459999944599999445999994459999944599944499444444994444449944499445999aaaaaaaaa5aaa5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
9999445999994459999944599999445999994459999944599999444449994444499944444999445999aaaaaaaa5a5a5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
9994449499944494999444949994449499944494999444949994544449945444499454444994449499aaaaaaaaaaa5aa5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
4455499444554994445549944455499444554994445549944444559949445599494455994955499444aaaaaaaa5aa555aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
4499944444999444449994444499944444999444449994444499994944999949449999494499944444aaaaaaaaa555aa5aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
4499944544999445449994454499944544999445449994454449944599499445994994459999944544aa994aaa5a55aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
5544445555444455554444555544445555444455554444555544445544444455444444554444445555aa4445aaaa555aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
4555499945554999455549994555499945554999455549994555499945554999455549994555499945944554999445549955499945aaaaaaaaaaaaaaaaaaaaaa
4444499444444994444449944444499444444994444449944444499444444994444449944444499444994459999944599944499444aaaaaaaaaaaaaaaaaaaaaa
4999444449994444499944444999444449994444499944444999444449994444499944444999444449994459999944599999444449aaaaaaaaaaaaaaaaaaaaaa
4994544449945444499454444994544449945444499454444994544449945444499454444994544449944494999444949994544449aaaaaaaaaaaaaaaaaaaaaa
4944559949445599494455994944559949445599494455994944559949445599494455994944559949554994445549944444559949aaaaaaaaaaaaaaaaaaaaaa
4499994944999949449999494499994944999949449999494499994944999949449999494499994944999444449994444499994944aaaaaaaaaaaaaaaaaaaaaa
9949944599499445994994459949944599499445994994459949944599499445994994459949944599999445449994454449944599aaaaaaaaaaaaaaaaaaaaaa
4444445544444455444444554444445544444455444444554444445544444455444444554444445544444455554444555544445544aaaaaaaaaaaaaaaaaaaaaa
45554999455549994555499945554999455549994555499945554999455549994555499945554999455549994555499945554999455577777777777777777777
44444994444449944444499444444994444449944444499444444994444449944444499444444994444449944444499444444994445577777777777777777777
49994444499944444999444449994444499944444999444449994444499944444999444449994444499944444999444449994444495554477777777777777777
49945444499454444994544449945444499454444994544449945444499454444994544449945444499454444994544449945444495555447777777777777777
49445599494455994944559949445599494455994944559949445599494455994944559949445599494455994944559949445599495555557777777777777777
44999949449999494499994944999949449999494499994944999949449999494499994944999949449999494499994944999949445555577777777777777777
99499445994994459949944599499445994994459949944599499445994994459949944599499445994994459949944599499445995555555777777777777777
44444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455445555555577777777777777
45554999455549994555499945554999455549994555499945554999455549994555499945554999455549994555499945554999459445549994455499777777
44444994444449944444499444444994444449944444499444444994444449944444499444444994444449944444499444444994449944599999445999777777
49994444499944444999444449994444499944444999444449994444499944444999444449994444499944444999444449994444499944599999445999777777
49945444499454444994544449945444499454444994544449945444499454444994544449945444499454444994544449945444499444949994449499777777
49445599494455994944559949445599494455994944559949445599494455994944559949445599494455994944559949445599495549944455499444777777
44999949449999494499994944999949449999494499994944999949449999494499994944999949449999494499994944999949449994444499944444777777
99499445994994459949944599499445994994459949944599499445994994459949944599499445994994459949944599499445999994454499944544777777
44444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444555544445555777777

__gff__
0000000000000000080808080000000000000101000001010000010000000000000000000000000000000000000000000000000000000000000008080808080001030100000000000003030103040404010000000000000000000301000404000002020000000000000000000000000000000300030000000000000404040000
0000000000000002010000010000000000030000000000000000000100080800000300000000000000000404040808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000006768000000004041414142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0067680000000000000000000000000000000000000000000000000000000000000000000000000000004546000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0045460000000000000000000000000000000000000000000000000000000000000000000000000000005556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055560000000000000000000000000000000000000000000000000000000000000000000000620000455747460000000000000000000000000000676800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
456566460000000000000000000000000000000000000000000000000067680000000000624344546055656656006f000000000000404200000000454600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41414141420000000000000000000000000000000000000000006f0000454600000000005041414141414141414141410000000000000000000000555600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
525353535400000000000067680000000060200000000000006f5f6f00555600000000005050505050505050505050504100000000000000000045574746006f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005152535300000000000045460000004041414200000000006c6d6e45574746000000004050505050505050505050505041000000000000000055574756005f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000052535400000000005556000000005042610000000000005f0055656656000000000050505050505050505050505050540000000060004557656647465f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000052530061620045656646600000505041000000000040505041414141420000000050505050505050505050504444535354004041414141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404141414141414141414141505050416160000000000052535351000000000050505050505050505050444453535353505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7373737373735050505050505050505050505050504141500000000043535100000000004050505050445167685251005253535050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6363636363645050505050505050505050505050505050505400000053530000000040505050505044510045460000000053535050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6363636364745050505050505050505050505050505050504141004353535400404150505050505051000055560000004353505050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6364727474505050505050505050505050505050505050505050414141414141415050505050504454004565664600435350505050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7474505050505050505050505050505050505050505050505050505050505050505050505050505041414141414141414150505050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000009494949494949494949494949494949494949594949494940000009a949900248b889b8899000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000007b7c7c7c949494949494949594949494949494949494949495949494009a9494949499008a9494949400000000209a990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000002500000000000000000000007b7c7d000000000000000000000000949492960093949293949494949494949494949494949494008b9b8894948b9b008a94949499009a9b8888889900000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002900000000000000000000006a7a000000000000000000000000000000000000000000000000009492000000009600009392a4949494949494920000939494008a949494949489000094898a94949494898a888899000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000006a4b5b7a00000000000000000000000000007b7c7c7d0000000000009200000000000000000000a494949494939200000000009300009a9494949400009a94009a94898a0000008a9494990000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006a7a00005969594b49495b7a00000000000000000000000000000000000000000000000000000000000000000023a494a5939200000000000000009a949494889b9499009494999b9499000000009a9494948800000000000000000000000000000000000000000000000000000000000000000000000000000000
0020597a59797969594b5a5a4949495a79797a6a69000000000000000000000000000000007b7d000000000000000000000001a494a5000000000000000000009494888888888894009488888888949900009a949494888800000000000000000000000000000000000000000000000000000000000000000000000000000000
49495a495a4a49495a494a49494a4949495b4b5a49494949007b7c7c7c7d00000000002200000000000000000000000000aaababababaca3a200000000000000888888888888888888888888888888888888889b8888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004d4e4f000000000000000000c0c1c1c1c1c1c1c2000000000000000000000000000000000020a3a201000000000093a49494a994920000000000000021222324250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005c5c5c006000000000000000d0d1d1d1d1d1d1d200000000000000007b7c7c7d0000000000aaababababac00000000a494a59200000000000001000022242125230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005c5d4e4e4f00000000210000d0d1d1d1d1d1d1d200000000000000000000000000000000a395949492000000000000a494a50000000000aaababac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005c5c5c5c5c00006700000000e0e1e1e1e1e1e1e200000000200000000000000000000000a8949494a2000001a3a200a494a500a3a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000020005c5c5c5c5c00004d4e4e4e4e000000000000000000007b7c7c7c7d000000000000000000a7a8949494a2aaabababac9794a5a39494a20000a3a2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004d4e4e5e5c5c5c00005c5c5c5c5c0000000000000000000000000000000000000000007b7c7ca7a7a894949794949494a6a7a80294949597a20194a6a8a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60005c5c5c5c5c5c5c00005c5c5c5c5c00000000000000000000000000000000000000000000000091919191919191919191919191919191919191919191919100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c00000000000000007c7c7d0000007b7c7c7c7c7d00000000a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001067400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800003c6753c4003c4003c4003c400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000c17534031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800003903139000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000181751f27521375181651f25521355181451f23521335181251f215213150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002a17312200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000012073366332a6231e61300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000211731d2431813315223113130c4130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01180000301710c161301510c141301310c1213011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001f04500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001804500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001862007610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002162521612000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003062530612000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001f0750c1752d045371451f0450c1452d035371351f0250c1252d025371251f0150c1152d0153711500005000050000500005000000000000000000000000000000000000000000000000000000000000
010c00001317421251241411f235151211f3111811100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002b072130321f0223700237002370020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000241320c211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f1752d231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002b17515231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001f1752b272370750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001307300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a000013375213752b3753037513355213552b3553035513345213452b3453034513335213352b3353033513325213152b3153031513315213152b315243051f305213051f3052430500000000000000000000
