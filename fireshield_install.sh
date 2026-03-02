bash <(cat << 'INSTALL_EOF'
set -e
echo "[1/4] Instalando dependencias..."
sudo apt-get update -qq

# Ubuntu 22.04+: policykit-1 fue reemplazado por polkitd/polkit
# gir1.2-webkit2-4.1 puede no estar disponible en 25.10, usar webkit2gtk-4.1 o 4.0
sudo apt-get install -y python3 python3-gi python3-pam ufw polkitd pkexec \
  gir1.2-gtk-3.0 \
  libwebkit2gtk-4.1-0 gir1.2-webkit2-4.1 2>/dev/null || \
sudo apt-get install -y python3 python3-gi python3-pam ufw polkitd pkexec \
  gir1.2-gtk-3.0 \
  libwebkit2gtk-4.0-37 gir1.2-webkit2-4.0 2>/dev/null || \
sudo apt-get install -y python3 python3-gi python3-pam ufw polkitd pkexec \
  gir1.2-gtk-3.0 \
  libwebkitgtk-6.0-4 gir1.2-webkit-6.0

echo "[2/4] Creando archivos..."
sudo mkdir -p /usr/share/fireshield
sudo tee /usr/share/fireshield/fireshield.py > /dev/null << 'PYEOF'
#!/usr/bin/env python3
import sys,os,subprocess,json,threading,http.server,socketserver,socket,signal,tempfile,atexit
HTML="""<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><title>FireShield</title><style>@import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Barlow:wght@400;600;700&display=swap');:root{--bg:#0a0c10;--surface:#0f1318;--panel:#141820;--border:#1e2530;--accent:#00e5ff;--accent2:#ff4757;--accent3:#2ed573;--warn:#ffa502;--text:#c8d6e5;--muted:#57606f;--mono:'Share Tech Mono',monospace;--sans:'Barlow',sans-serif}*{box-sizing:border-box;margin:0;padding:0}body{background:var(--bg);color:var(--text);font-family:var(--sans);min-height:100vh}body::before{content:'';position:fixed;inset:0;background-image:linear-gradient(rgba(0,229,255,.03) 1px,transparent 1px),linear-gradient(90deg,rgba(0,229,255,.03) 1px,transparent 1px);background-size:40px 40px;pointer-events:none;z-index:0}header{position:relative;z-index:10;display:flex;align-items:center;justify-content:space-between;padding:16px 32px;border-bottom:1px solid var(--border);background:rgba(15,19,24,.95)}.logo{display:flex;align-items:center;gap:12px}.logo-text{font-family:var(--mono);font-size:20px;color:var(--accent);letter-spacing:2px;text-shadow:0 0 20px rgba(0,229,255,.5)}.logo-sub{font-size:11px;color:var(--muted);letter-spacing:3px;text-transform:uppercase}.sbadge{display:flex;align-items:center;gap:8px;padding:6px 16px;border-radius:2px;font-family:var(--mono);font-size:13px;border:1px solid currentColor;cursor:pointer;letter-spacing:1px}.sbadge.on{color:var(--accent3);background:rgba(46,213,115,.08)}.sbadge.off{color:var(--accent2);background:rgba(255,71,87,.08)}.sdot{width:8px;height:8px;border-radius:50%;background:currentColor;animation:pulse 2s infinite}.sbadge.off .sdot{animation:none}@keyframes pulse{0%,100%{opacity:1}50%{opacity:.5}}.main{display:grid;grid-template-columns:250px 1fr;height:calc(100vh - 69px)}.sidebar{border-right:1px solid var(--border);background:var(--surface);display:flex;flex-direction:column;overflow-y:auto}.ss{padding:18px;border-bottom:1px solid var(--border)}.sl{font-family:var(--mono);font-size:10px;color:var(--muted);letter-spacing:3px;text-transform:uppercase;margin-bottom:14px}.sg{display:grid;grid-template-columns:1fr 1fr;gap:7px}.sc{background:var(--panel);border:1px solid var(--border);padding:11px;position:relative;overflow:hidden}.sc::before{content:'';position:absolute;top:0;left:0;right:0;height:2px;background:var(--accent)}.sc.d::before{background:var(--accent2)}.sc.s::before{background:var(--accent3)}.sc.w::before{background:var(--warn)}.sv{font-family:var(--mono);font-size:22px;color:var(--accent);line-height:1}.sc.d .sv{color:var(--accent2)}.sc.s .sv{color:var(--accent3)}.sc.w .sv{color:var(--warn)}.sk{font-size:10px;color:var(--muted);letter-spacing:1px;margin-top:3px;text-transform:uppercase}.ni{display:flex;align-items:center;gap:9px;padding:9px 11px;cursor:pointer;font-size:14px;font-weight:600;color:var(--muted);transition:all .15s;border:1px solid transparent;margin-bottom:2px;border-radius:2px}.ni:hover{color:var(--text);background:var(--panel)}.ni.on{color:var(--accent);background:rgba(0,229,255,.06);border-color:rgba(0,229,255,.2)}.content{display:flex;flex-direction:column;overflow:hidden}.ch{padding:18px 26px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}.ct{font-size:17px;font-weight:700;letter-spacing:1px}.cb{flex:1;overflow-y:auto;padding:22px 26px}.tv{display:none}.tv.on{display:block}.btn{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;border:1px solid var(--border);background:var(--panel);color:var(--text);font-family:var(--mono);font-size:12px;letter-spacing:1px;cursor:pointer;border-radius:2px;transition:all .15s}.btn:hover{border-color:var(--accent);color:var(--accent)}.btn.p{border-color:var(--accent);color:var(--accent);background:rgba(0,229,255,.06)}.btn.p:hover{background:rgba(0,229,255,.15)}.btn.d{border-color:var(--accent2);color:var(--accent2);background:rgba(255,71,87,.06)}table{width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12px}thead tr{background:var(--panel);border-bottom:2px solid var(--accent)}thead th{padding:9px 12px;text-align:left;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--accent);font-weight:400}tbody tr{border-bottom:1px solid var(--border)}tbody tr:hover{background:rgba(255,255,255,.02)}tbody td{padding:9px 12px;vertical-align:middle}.badge{display:inline-block;padding:2px 7px;border-radius:1px;font-size:10px;letter-spacing:1px;font-weight:600;border:1px solid currentColor}.ba{color:var(--accent3);background:rgba(46,213,115,.1)}.bd{color:var(--accent2);background:rgba(255,71,87,.1)}.bl{color:var(--warn);background:rgba(255,165,2,.1)}.bt{color:var(--accent);background:rgba(0,229,255,.1)}.bu{color:#a29bfe;background:rgba(162,155,254,.1)}.bx{color:var(--muted);background:rgba(87,96,111,.1)}.ib{width:26px;height:26px;display:flex;align-items:center;justify-content:center;border:1px solid var(--border);background:transparent;color:var(--muted);cursor:pointer;border-radius:2px;font-size:11px;transition:all .15s}.ib:hover{border-color:var(--accent2);color:var(--accent2)}.mo{position:fixed;inset:0;background:rgba(0,0,0,.8);z-index:100;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}.mo.on{opacity:1;pointer-events:all}.md{background:var(--surface);border:1px solid var(--border);width:500px;max-width:95vw;transform:translateY(20px);transition:transform .2s}.mo.on .md{transform:translateY(0)}.mh{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;background:var(--panel)}.mt{font-family:var(--mono);font-size:13px;color:var(--accent);letter-spacing:2px}.mc{background:none;border:none;color:var(--muted);font-size:17px;cursor:pointer}.mb{padding:18px}.mf{padding:12px 18px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:9px;background:var(--panel)}.fr{display:grid;grid-template-columns:1fr 1fr;gap:11px;margin-bottom:11px}.fg{display:flex;flex-direction:column;gap:5px}.fg.f{grid-column:1/-1}label{font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--muted);font-family:var(--mono)}input,select{background:var(--panel);border:1px solid var(--border);color:var(--text);padding:7px 11px;font-family:var(--mono);font-size:12px;border-radius:2px;outline:none;transition:border-color .15s}input:focus,select:focus{border-color:var(--accent)}select option{background:var(--panel)}.cp{background:#060809;border:1px solid var(--border);border-left:3px solid var(--accent);padding:9px 13px;font-family:var(--mono);font-size:11px;color:var(--accent);margin-bottom:14px}.pg{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:14px;margin-top:14px}.pc{background:var(--panel);border:1px solid var(--border);padding:18px;cursor:pointer;transition:all .2s;position:relative;overflow:hidden}.pc::after{content:'';position:absolute;bottom:0;left:0;right:0;height:3px;background:var(--accent);transform:scaleX(0);transition:transform .2s}.pc:hover{border-color:var(--accent)}.pc:hover::after{transform:scaleX(1)}.pi{font-size:26px;margin-bottom:10px}.pn{font-weight:700;font-size:14px;margin-bottom:3px}.pd{font-size:11px;color:var(--muted);line-height:1.5}.le{display:flex;align-items:center;gap:11px;padding:9px 0;border-bottom:1px solid var(--border);font-family:var(--mono);font-size:11px}.lt{color:var(--muted);min-width:75px}.tw{display:flex;align-items:center;gap:9px;padding:9px 14px;background:var(--panel);border:1px solid var(--border);border-radius:2px;margin-bottom:7px}.tl{font-size:13px;font-weight:600}.ts{font-size:11px;color:var(--muted)}.sw{position:relative;width:42px;height:21px;margin-left:auto}.sw input{opacity:0;width:0;height:0}.sl2{position:absolute;inset:0;background:var(--border);border-radius:11px;cursor:pointer;transition:.3s}.sl2::before{content:'';position:absolute;width:15px;height:15px;left:3px;top:3px;background:var(--muted);border-radius:50%;transition:.3s}input:checked+.sl2{background:rgba(46,213,115,.3)}input:checked+.sl2::before{transform:translateX(21px);background:var(--accent3)}.nt{position:fixed;bottom:22px;right:22px;z-index:200;display:none;background:var(--panel);border:1px solid var(--accent);color:var(--accent);padding:9px 18px;font-family:var(--mono);font-size:12px;border-radius:2px}::-webkit-scrollbar{width:4px}::-webkit-scrollbar-track{background:var(--bg)}::-webkit-scrollbar-thumb{background:var(--border)}.tb{display:flex;align-items:center;gap:11px;margin-bottom:14px;flex-wrap:wrap}.ha{display:flex;gap:7px}</style></head><body>
<header><div class="logo"><svg width="34" height="34" viewBox="0 0 36 36" fill="none"><path d="M18 2L4 8V18C4 25.7 10.3 32.9 18 34C25.7 32.9 32 25.7 32 18V8L18 2Z" stroke="#00e5ff" stroke-width="1.5" fill="rgba(0,229,255,0.06)"/><path d="M12 18L16 22L24 14" stroke="#00e5ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg><div><div class="logo-text">FIRESHIELD</div><div class="logo-sub">Ubuntu Firewall Manager</div></div></div><div id="sb" class="sbadge on" onclick="toggleUFW()"><span class="sdot"></span><span id="st">CARGANDO...</span></div></header>
<div class="main"><div class="sidebar"><div class="ss"><div class="sl">Estado</div><div class="sg"><div class="sc s"><div class="sv" id="sA">-</div><div class="sk">Permitir</div></div><div class="sc d"><div class="sv" id="sD">-</div><div class="sk">Denegar</div></div><div class="sc w"><div class="sv" id="sL">-</div><div class="sk">Limitar</div></div><div class="sc"><div class="sv" id="sT">-</div><div class="sk">Total</div></div></div></div><div class="ss"><div class="sl">Navegación</div><div class="ni on" onclick="tab('rules',this)">🛡 Reglas</div><div class="ni" onclick="tab('profiles',this)">📦 Perfiles</div><div class="ni" onclick="tab('advanced',this)">⚙ Avanzado</div><div class="ni" onclick="tab('log',this)">📋 Registro</div></div><div class="ss"><div class="sl">Política defecto</div><div style="font-family:var(--mono);font-size:11px;line-height:2"><span style="color:var(--muted)">ENTRADA:</span> <span id="pI" style="color:var(--accent2)">DENY</span><br><span style="color:var(--muted)">SALIDA:</span> <span id="pO" style="color:var(--accent3)">ALLOW</span></div></div></div>
<div class="content">
<div id="tv-rules" class="tv on"><div class="ch"><div class="ct">Reglas del Cortafuegos</div><div class="ha"><button class="btn" onclick="load()">↻ Actualizar</button><button class="btn p" onclick="openM()">+ Nueva Regla</button></div></div><div class="cb"><div class="tb"><select id="fA" onchange="render()" style="width:110px"><option value="">Todo</option><option value="ALLOW">Permitir</option><option value="DENY">Denegar</option><option value="LIMIT">Limitar</option></select><select id="fD" onchange="render()" style="width:110px"><option value="">Dirección</option><option value="IN">Entrada</option><option value="OUT">Salida</option></select></div><table><thead><tr><th>#</th><th>Acción</th><th>Puerto</th><th>Proto</th><th>Origen</th><th>Dir</th><th>Comentario</th><th></th></tr></thead><tbody id="rb"><tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)">Cargando...</td></tr></tbody></table></div></div>
<div id="tv-profiles" class="tv"><div class="ch"><div class="ct">Perfiles de Seguridad</div></div><div class="cb"><p style="color:var(--muted);font-size:13px;margin-bottom:4px">Aplica configuraciones preestablecidas. Requiere contraseña de administrador.</p><div class="pg"><div class="pc" onclick="prof('web')"><div class="pi">🌐</div><div class="pn">Servidor Web</div><div class="pd">HTTP, HTTPS y SSH limitado.</div></div><div class="pc" onclick="prof('dev')"><div class="pi">💻</div><div class="pn">Desarrollo</div><div class="pd">SSH, HTTP, PostgreSQL, Redis.</div></div><div class="pc" onclick="prof('strict')"><div class="pi">🔒</div><div class="pn">Máxima Seguridad</div><div class="pd">Solo SSH limitado.</div></div><div class="pc" onclick="prof('mail')"><div class="pi">📧</div><div class="pn">Servidor Correo</div><div class="pd">SMTP, IMAP, POP3, HTTPS.</div></div><div class="pc" onclick="prof('reset')" style="border-color:rgba(255,71,87,.3)"><div class="pi">🔄</div><div class="pn">Resetear UFW</div><div class="pd" style="color:var(--accent2)">Elimina TODAS las reglas.</div></div></div></div></div>
<div id="tv-advanced" class="tv"><div class="ch"><div class="ct">Configuración Avanzada</div></div><div class="cb"><div style="font-family:var(--mono);font-size:11px;letter-spacing:3px;color:var(--accent);margin-bottom:14px;padding-bottom:7px;border-bottom:1px solid var(--border)">POLÍTICA POR DEFECTO</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:11px;max-width:460px;margin-bottom:22px"><div class="fg"><label>Tráfico Entrante</label><select id="aI" onchange="setDef()"><option value="deny">DENY</option><option value="allow">ALLOW</option><option value="reject">REJECT</option></select></div><div class="fg"><label>Tráfico Saliente</label><select id="aO" onchange="setDef()"><option value="allow">ALLOW</option><option value="deny">DENY</option><option value="reject">REJECT</option></select></div></div><div style="font-family:var(--mono);font-size:11px;letter-spacing:3px;color:var(--accent);margin-bottom:14px;padding-bottom:7px;border-bottom:1px solid var(--border)">OPCIONES</div><div style="max-width:460px"><div class="tw"><div><div class="tl">Registro de eventos</div><div class="ts">/var/log/ufw.log</div></div><label class="sw"><input type="checkbox" checked id="tL" onchange="setLog()"><span class="sl2"></span></label></div></div></div></div>
<div id="tv-log" class="tv"><div class="ch"><div class="ct">Registro de Actividad</div><button class="btn" onclick="clearLog()">🗑 Limpiar</button></div><div class="cb" id="lb"><div style="text-align:center;padding:60px;color:var(--muted)">Sin eventos aún</div></div></div>
</div></div>
<div class="mo" id="mo" onclick="if(event.target===this)closeM()"><div class="md"><div class="mh"><span class="mt">// NUEVA REGLA</span><button class="mc" onclick="closeM()">✕</button></div><div class="mb"><div id="cp" class="cp">$ sudo ufw allow 80/tcp</div><div class="fr"><div class="fg"><label>Acción</label><select id="fAc" onchange="prev()"><option value="allow">ALLOW</option><option value="deny">DENY</option><option value="reject">REJECT</option><option value="limit">LIMIT</option></select></div><div class="fg"><label>Dirección</label><select id="fDi" onchange="prev()"><option value="">Ambas</option><option value="in">IN</option><option value="out">OUT</option></select></div></div><div class="fr"><div class="fg"><label>Puerto</label><input type="text" id="fP" placeholder="80, 443, 8000:9000" oninput="prev()"></div><div class="fg"><label>Protocolo</label><select id="fPr" onchange="prev()"><option value="tcp">TCP</option><option value="udp">UDP</option><option value="">Ambos</option></select></div></div><div class="fr"><div class="fg"><label>IP Origen</label><input type="text" id="fF" placeholder="192.168.1.0/24" oninput="prev()"></div><div class="fg"><label>IP Destino</label><input type="text" id="fT" placeholder="10.0.0.1" oninput="prev()"></div></div><div class="fr"><div class="fg f"><label>Comentario</label><input type="text" id="fC" placeholder="Descripción" oninput="prev()"></div></div></div><div class="mf"><button class="btn" onclick="closeM()">Cancelar</button><button class="btn p" onclick="addR()">+ Agregar</button></div></div></div>
<div class="nt" id="nt"></div>
<script>
const API='http://127.0.0.1:__PORT__';
let rules=[],logs=[];
async function api(p,o={}){try{const r=await fetch(API+p,o);return await r.json()}catch(e){return{ok:false,msg:String(e)}}}
async function load(){
 const d=await api('/api/status');
 const sb=document.getElementById('sb'),st=document.getElementById('st');
 if(d.active){sb.className='sbadge on';st.textContent='UFW ACTIVO'}
 else{sb.className='sbadge off';st.textContent='UFW INACTIVO'}
 rules=d.rules||[];
 document.getElementById('sA').textContent=rules.filter(r=>r.action==='ALLOW').length;
 document.getElementById('sD').textContent=rules.filter(r=>r.action==='DENY').length;
 document.getElementById('sL').textContent=rules.filter(r=>r.action==='LIMIT').length;
 document.getElementById('sT').textContent=rules.length;
 if(d.raw){const m1=d.raw.match(/Default: (\w+) \(incoming\)/i),m2=d.raw.match(/(\w+) \(outgoing\)/i);if(m1)document.getElementById('pI').textContent=m1[1].toUpperCase();if(m2)document.getElementById('pO').textContent=m2[1].toUpperCase()}
 render();
}
function render(){
 const fa=document.getElementById('fA').value,fd=document.getElementById('fD').value;
 const f=rules.filter(r=>(!fa||r.action===fa)&&(!fd||r.direction===fd));
 const tb=document.getElementById('rb');
 if(!f.length){tb.innerHTML='<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)">Sin reglas</td></tr>';return}
 tb.innerHTML=f.map(r=>{
 const ab=r.action==='ALLOW'?'a':r.action==='DENY'?'d':'l';
 const[port,proto]=r.port_proto.includes('/')?r.port_proto.split('/'):[r.port_proto,''];
 return`<tr><td style="color:var(--muted)">${r.num}</td><td><span class="badge b${ab}">${r.action}</span></td><td>${port||'any'}</td><td><span class="badge b${proto?proto[0]:'x'}">${proto||'ANY'}</span></td><td style="color:${r.from!=='Anywhere'?'var(--accent)':'var(--muted)'}">${r.from}</td><td><span class="badge bx">${r.direction}</span></td><td style="color:var(--muted)">${r.comment}</td><td><button class="ib" onclick="delR('${r.num}')">✕</button></td></tr>`;
 }).join('');
}
async function delR(n){if(!confirm(`¿Eliminar regla #${n}?`))return;const d=await api(`/api/delete?num=${n}`);toast(d.ok?`Regla #${n} eliminada`:`Error: ${d.msg}`,!d.ok);log('DELETE',`Regla #${n}`);if(d.ok)load()}
async function toggleUFW(){
 const on=document.getElementById('sb').classList.contains('on');
 if(on){if(!confirm('¿Desactivar cortafuegos?'))return;const d=await api('/api/disable');toast(d.ok?'Desactivado':d.msg,!d.ok);if(!d.ok)return;}
 else{const d=await api('/api/enable');toast(d.ok?'Activado':d.msg,!d.ok);if(!d.ok)return;}
 log(on?'DISABLE':'ENABLE',on?'UFW off':'UFW on');
 // Esperar 1.5s para que UFW aplique el cambio antes de leer el estado
 setTimeout(()=>load(),1500);
}
function openM(){document.getElementById('mo').classList.add('on');prev()}
function closeM(){document.getElementById('mo').classList.remove('on')}
function prev(){const a=document.getElementById('fAc').value,di=document.getElementById('fDi').value,p=document.getElementById('fP').value,pr=document.getElementById('fPr').value,f=document.getElementById('fF').value,t=document.getElementById('fT').value,c=document.getElementById('fC').value;let cmd=`sudo ufw ${a}${di?' '+di:''}`;if(f)cmd+=` from ${f}`;if(t)cmd+=` to ${t}`;if(p)cmd+=` ${p}${pr?'/'+pr:''}`;if(c)cmd+=` comment '${c}'`;document.getElementById('cp').textContent='$ '+cmd}
async function addR(){const p=document.getElementById('fP').value,f=document.getElementById('fF').value;if(!p&&!f){toast('Especifica puerto o IP',true);return}const b={action:document.getElementById('fAc').value,direction:document.getElementById('fDi').value,port:p,proto:document.getElementById('fPr').value,from:f,to:document.getElementById('fT').value,comment:document.getElementById('fC').value};const d=await api('/api/rule',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(b)});toast(d.ok?'✓ Regla agregada':`Error: ${d.msg}`,!d.ok);log('ADD',`${b.action} ${p||f}`);if(d.ok){closeM();load()}}
const profs={web:[{a:'allow',p:'80',pr:'tcp',c:'HTTP'},{a:'allow',p:'443',pr:'tcp',c:'HTTPS'},{a:'limit',p:'22',pr:'tcp',c:'SSH'}],dev:[{a:'allow',p:'22',pr:'tcp',c:'SSH'},{a:'allow',p:'80',pr:'tcp',c:'HTTP'},{a:'allow',p:'5432',pr:'tcp',c:'PostgreSQL'},{a:'allow',p:'6379',pr:'tcp',c:'Redis'}],strict:[{a:'limit',p:'22',pr:'tcp',c:'Solo SSH'}],mail:[{a:'allow',p:'25',pr:'tcp',c:'SMTP'},{a:'allow',p:'587',pr:'tcp',c:'Submission'},{a:'allow',p:'993',pr:'tcp',c:'IMAPS'},{a:'allow',p:'443',pr:'tcp',c:'Webmail'}]};
async function prof(n){if(n==='reset'){if(!confirm('¿Resetear TODO?'))return;const d=await api('/api/reset');toast(d.ok?'✓ Reseteado':d.msg,!d.ok);log('RESET','UFW reset');load();return}const rs=profs[n];if(!confirm(`¿Aplicar perfil ${n}? (${rs.length} reglas)`))return;for(const r of rs)await api('/api/rule',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:r.a,port:r.p,proto:r.pr,comment:r.c,direction:'',from:'',to:''})});toast(`✓ Perfil ${n}`);log('PROFILE',n);load()}
async function setDef(){await api(`/api/default?dir=incoming&policy=${document.getElementById('aI').value}`);await api(`/api/default?dir=outgoing&policy=${document.getElementById('aO').value}`);toast('✓ Política actualizada');load()}
async function setLog(){await api(`/api/logging?on=${document.getElementById('tL').checked?1:0}`);toast('✓ Logging actualizado')}
function log(t,d){const time=new Date().toTimeString().slice(0,8);logs.unshift({time,t,d});if(logs.length>100)logs.pop();document.getElementById('lb').innerHTML=logs.map(e=>`<div class="le"><span class="lt">${e.time}</span><span class="badge bx" style="min-width:55px;text-align:center">${e.t}</span><span>${e.d}</span></div>`).join('')}
function clearLog(){logs=[];document.getElementById('lb').innerHTML='<div style="text-align:center;padding:60px;color:var(--muted)">Sin eventos</div>'}
let tt;function toast(m,e=false){const n=document.getElementById('nt');n.textContent=m;n.style.borderColor=e?'var(--accent2)':'var(--accent)';n.style.color=e?'var(--accent2)':'var(--accent)';n.style.display='block';clearTimeout(tt);tt=setTimeout(()=>n.style.display='none',3000)}
function tab(t,el){document.querySelectorAll('.tv').forEach(x=>x.classList.remove('on'));document.querySelectorAll('.ni').forEach(x=>x.classList.remove('on'));document.getElementById('tv-'+t).classList.add('on');if(el)el.classList.add('on')}
load();setInterval(load,10000);
</script></body></html>"""

def run_priv(cmd):
 try:
  r=subprocess.run(["sudo","-n"]+cmd,capture_output=True,text=True,timeout=60)
  return r.returncode==0,(r.stdout+r.stderr).strip()
 except subprocess.TimeoutExpired: return False,"Tiempo agotado"
 except Exception as e: return False,str(e)

def ufw_raw():
 try:
  r=subprocess.run(["sudo","-n","ufw","status","verbose"],capture_output=True,text=True,timeout=10)
  if r.returncode==0 and r.stdout.strip(): return r.stdout
  # fallback: detectar via systemctl si ufw esta activo
  r2=subprocess.run(["systemctl","is-active","ufw"],capture_output=True,text=True,timeout=5)
  if r2.stdout.strip()=="active": return "Estado: activo\n(detected via systemctl)"
  return "Status: inactive\n"
 except Exception as e: return f"Error:{e}"

def ufw_numbered():
 try:
  r=subprocess.run(["sudo","-n","ufw","status","numbered"],capture_output=True,text=True,timeout=10)
  rules=[]
  for line in r.stdout.splitlines():
   line=line.strip()
   if not line.startswith("["): continue
   try:
    end=line.index("]"); num=line[1:end].strip(); rest=line[end+1:].strip()
    parts=rest.split(); pp=parts[0] if parts else "?"; action=parts[1] if len(parts)>1 else "?"
    direction=parts[2] if len(parts)>2 and parts[2] in("IN","OUT","FWD") else "IN"
    src=parts[3] if len(parts)>3 else "Anywhere"
    comment=rest.split("#",1)[1].strip() if "#" in rest else ""
    rules.append({"num":num,"port_proto":pp,"action":action,"direction":direction,"from":src,"comment":comment})
   except: continue
  return rules
 except: return []

def ufw_add(action,port,proto,from_ip,to_ip,direction,comment):
 cmd=["ufw"]
 if direction.lower() in("in","out"): cmd+=[action,direction]
 else: cmd.append(action)
 if from_ip and from_ip not in("any","Anywhere",""): cmd+=["from",from_ip]
 if to_ip and to_ip not in("any","Anywhere",""): cmd+=["to",to_ip]
 if port and port not in("any",""): cmd.append(f"{port}/{proto}" if proto else port)
 elif proto: cmd+=["proto",proto]
 if comment: cmd+=["comment",comment]
 return run_priv(cmd)

class H(http.server.SimpleHTTPRequestHandler):
 def log_message(self,*a): pass
 def sj(self,d):
  b=json.dumps(d).encode(); self.send_response(200)
  self.send_header("Content-Type","application/json"); self.send_header("Content-Length",len(b))
  self.send_header("Access-Control-Allow-Origin","*"); self.end_headers(); self.wfile.write(b)
 def sh(self):
  b=self.html.encode("utf-8"); self.send_response(200)
  self.send_header("Content-Type","text/html;charset=utf-8"); self.send_header("Content-Length",len(b))
  self.end_headers(); self.wfile.write(b)
 def do_OPTIONS(self):
  self.send_response(200); self.send_header("Access-Control-Allow-Origin","*")
  self.send_header("Access-Control-Allow-Methods","GET,POST,OPTIONS")
  self.send_header("Access-Control-Allow-Headers","Content-Type"); self.end_headers()
 def do_GET(self):
  from urllib.parse import urlparse,parse_qs
  p=urlparse(self.path); q=parse_qs(p.query)
  if p.path in("/","/index.html"): return self.sh()
  if p.path=="/api/status":
   raw=ufw_raw(); active=any(x in raw for x in ["Status: active","Estado: activo","Status: activo","Estado: active"])
   return self.sj({"active":active,"raw":raw,"rules":ufw_numbered() if active else []})
  if p.path=="/api/enable": ok,m=run_priv(["ufw","enable"]); return self.sj({"ok":ok,"msg":m})
  if p.path=="/api/disable": ok,m=run_priv(["ufw","disable"]); return self.sj({"ok":ok,"msg":m})
  if p.path=="/api/reset": ok,m=run_priv(["ufw","--force","reset"]); return self.sj({"ok":ok,"msg":m})
  if p.path=="/api/delete": ok,m=run_priv(["ufw","--force","delete",q.get("num",[""])[0]]); return self.sj({"ok":ok,"msg":m})
  if p.path=="/api/logging": ok,m=run_priv(["ufw","logging","on" if q.get("on",["1"])[0]=="1" else "off"]); return self.sj({"ok":ok,"msg":m})
  if p.path=="/api/default": ok,m=run_priv(["ufw","default",q.get("policy",["deny"])[0],q.get("dir",["incoming"])[0]]); return self.sj({"ok":ok,"msg":m})
  self.send_error(404)
 def do_POST(self):
  from urllib.parse import urlparse
  p=urlparse(self.path); length=int(self.headers.get("Content-Length",0))
  try: data=json.loads(self.rfile.read(length))
  except: data={}
  if p.path=="/api/rule":
   ok,m=ufw_add(data.get("action","allow"),data.get("port",""),data.get("proto",""),data.get("from",""),data.get("to",""),data.get("direction",""),data.get("comment",""))
   return self.sj({"ok":ok,"msg":m})
  self.send_error(404)

def make_handler(html,port):
 class HH(H): pass
 HH.html=html; HH.port=port; return HH

def find_port():
 with socket.socket() as s: s.bind(("127.0.0.1",0)); return s.getsockname()[1]

def get_webkit_version():
 """Detecta la versión de WebKit disponible en el sistema"""
 import gi
 for version, module in [("4.1", "WebKit2"), ("4.0", "WebKit2"), ("6.0", "WebKit")]:
  try:
   if module == "WebKit2":
    gi.require_version("WebKit2", version)
    from gi.repository import WebKit2
    return "WebKit2", version, WebKit2
   else:
    gi.require_version("WebKit", version)
    from gi.repository import WebKit
    return "WebKit", version, WebKit
  except (ValueError, ImportError):
   continue
 return None, None, None

def check_password(password):
 try:
  import pam
  p=pam.pam()
  return p.authenticate(os.getenv("USER") or os.getenv("LOGNAME") or subprocess.run(["whoami"],capture_output=True,text=True).stdout.strip(), password)
 except ImportError:
  # fallback: usar su para verificar password
  try:
   user=os.getenv("USER") or subprocess.run(["whoami"],capture_output=True,text=True).stdout.strip()
   nl=chr(10);r=subprocess.run(["su","-c","true",user],input=password+nl,capture_output=True,text=True,timeout=5)
   return r.returncode==0
  except: return False

def show_login(Gtk):
 dlg=Gtk.Dialog(title="FireShield — Acceso", flags=0)
 dlg.set_default_size(360,0)
 dlg.set_position(Gtk.WindowPosition.CENTER)
 dlg.set_deletable(False)
 dlg.set_resizable(False)

 box=dlg.get_content_area()
 box.set_spacing(0)
 box.set_border_width(0)

 # Header
 header=Gtk.Box()
 header.set_orientation(Gtk.Orientation.VERTICAL)
 header.get_style_context().add_class("login-header")
 header.set_border_width(24)
 header.set_spacing(6)

 icon_label=Gtk.Label()
 icon_label.set_markup('<span font="24">🛡</span>')
 title_label=Gtk.Label()
 title_label.set_markup('<span font="16" weight="bold" foreground="#00e5ff">FIRESHIELD</span>')
 sub_label=Gtk.Label()
 sub_label.set_markup('<span font="11" foreground="#57606f">Ingresa tu contraseña de usuario</span>')

 header.pack_start(icon_label,False,False,0)
 header.pack_start(title_label,False,False,0)
 header.pack_start(sub_label,False,False,0)
 box.pack_start(header,False,False,0)

 # Form
 form=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=12)
 form.set_border_width(24)

 entry=Gtk.Entry()
 entry.set_visibility(False)
 entry.set_placeholder_text("Contraseña")
 entry.set_input_purpose(Gtk.InputPurpose.PASSWORD)

 error_label=Gtk.Label()
 error_label.set_markup('<span foreground="#ff4757" font="11"> </span>')

 btn=Gtk.Button(label="Entrar")

 form.pack_start(entry,False,False,0)
 form.pack_start(error_label,False,False,0)
 form.pack_start(btn,False,False,0)
 box.pack_start(form,False,False,0)

 dlg.show_all()
 result={"ok":False,"attempts":0}

 def try_login(*a):
  pwd=entry.get_text()
  if not pwd: return
  btn.set_sensitive(False)
  btn.set_label("Verificando...")
  # Procesar eventos para actualizar UI
  while Gtk.events_pending(): Gtk.main_iteration()
  if check_password(pwd):
   result["ok"]=True
   dlg.response(Gtk.ResponseType.OK)
  else:
   result["attempts"]+=1
   entry.set_text("")
   error_label.set_markup(f'<span foreground="#ff4757" font="11">Contraseña incorrecta (intento {result["attempts"]})</span>')
   btn.set_sensitive(True)
   btn.set_label("Entrar")
   entry.grab_focus()

 btn.connect("clicked",try_login)
 entry.connect("activate",try_login)
 dlg.run()
 dlg.destroy()
 return result["ok"]

def main():
 port=find_port(); url=f"http://127.0.0.1:{port}"
 html=HTML.replace("__PORT__",str(port))
 server=socketserver.TCPServer(("127.0.0.1",port),make_handler(html,port))
 server.allow_reuse_address=True
 threading.Thread(target=server.serve_forever,daemon=True).start()
 signal.signal(signal.SIGINT,lambda s,f:(server.shutdown(),sys.exit(0)))
 signal.signal(signal.SIGTERM,lambda s,f:(server.shutdown(),sys.exit(0)))
 import gi
 gi.require_version("Gtk","3.0")
 from gi.repository import Gtk

 # Mostrar login antes de la ventana principal
 if not show_login(Gtk):
  server.shutdown()
  sys.exit(0)

 webkit_module, webkit_version, WebKitLib = get_webkit_version()
 if not WebKitLib:
  print("Error: No se encontró WebKit. Instala libwebkit2gtk-4.1-0 o libwebkitgtk-6.0-4")
  sys.exit(1)

 win=Gtk.Window(); win.set_title("FireShield — Cortafuegos Ubuntu")
 win.set_default_size(1280,800); win.set_position(Gtk.WindowPosition.CENTER)
 win.connect("destroy",Gtk.main_quit)
 hb=Gtk.HeaderBar(); hb.set_show_close_button(True); hb.set_title("FireShield")
 hb.set_subtitle("Cortafuegos UFW"); win.set_titlebar(hb)

 if webkit_module == "WebKit2":
  s=WebKitLib.Settings(); s.set_enable_javascript(True)
  wv=WebKitLib.WebView.new_with_settings(s)
  def pol(w,d,t):
   if t==WebKitLib.PolicyDecisionType.NAVIGATION_ACTION:
    uri=d.get_navigation_action().get_request().get_uri()
    if not uri.startswith(f"http://127.0.0.1:{port}"): d.ignore(); return True
   d.use(); return False
  wv.connect("decide-policy",pol)
 else:
  wv=WebKitLib.WebView()

 wv.load_uri(url); win.add(wv); win.show_all(); Gtk.main()
 server.shutdown()

if __name__=="__main__": main()
PYEOF

echo "[2b/4] Configurando permisos UFW sin contrasena..."
SUDOERS_FILE="/etc/sudoers.d/fireshield"
CURRENT_USER="${SUDO_USER:-$(whoami)}"
UFW_PATH=$(which ufw 2>/dev/null || echo "/usr/sbin/ufw")
sudo tee "$SUDOERS_FILE" > /dev/null << SUDOEOF
$CURRENT_USER ALL=(ALL) NOPASSWD: $UFW_PATH
$CURRENT_USER ALL=(ALL) NOPASSWD: $UFW_PATH *
SUDOEOF
sudo chmod 0440 "$SUDOERS_FILE"
sudo visudo -c -f "$SUDOERS_FILE" 2>/dev/null && echo "   Permisos OK para: $CURRENT_USER" || echo "   ERROR en sudoers"

echo "[3/4] Instalando lanzador..."
sudo tee /usr/local/bin/fireshield > /dev/null << 'EOF'
#!/bin/bash
exec python3 /usr/share/fireshield/fireshield.py "$@"
EOF
sudo chmod +x /usr/local/bin/fireshield
sudo tee /usr/share/applications/fireshield.desktop > /dev/null << 'EOF'
[Desktop Entry]
Version=1.1
Type=Application
Name=FireShield
GenericName=Cortafuegos Ubuntu
Comment=Gestor grafico del cortafuegos UFW para Ubuntu
Exec=/usr/local/bin/fireshield
Icon=utilities-system
Terminal=false
Categories=System;Settings;Security;Network;
StartupNotify=true
EOF
update-desktop-database /usr/share/applications 2>/dev/null || true
echo ""
echo "[4/4] ¡Listo! Ejecuta: fireshield"
INSTALL_EOF
)
