bash <(cat << 'SCRIPT_EOF'
set -e
echo "[1/4] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y python3 python3-gi python3-pam ufw polkitd pkexec \
  gir1.2-gtk-3.0 \
  libwebkit2gtk-4.1-0 gir1.2-webkit2-4.1 2>/dev/null || \
sudo apt-get install -y python3 python3-gi python3-pam ufw polkitd pkexec \
  gir1.2-gtk-3.0 \
  libwebkit2gtk-4.0-37 gir1.2-webkit2-4.0 2>/dev/null || \
sudo apt-get install -y python3 python3-gi python3-pam ufw polkitd pkexec \
  gir1.2-gtk-3.0 \
  libwebkitgtk-6.0-4 gir1.2-webkit-6.0

echo "[2/4] Creating files..."
sudo mkdir -p /usr/share/fireshield
sudo tee /usr/share/fireshield/fireshield.py > /dev/null << 'PYEOF'
#!/usr/bin/env python3
import sys,os,subprocess,json,threading,http.server,socketserver,socket,signal,locale

# ── Language detection ──────────────────────────────────────────────────────
def detect_lang():
    for v in ["LANG","LANGUAGE","LC_ALL","LC_MESSAGES"]:
        val=os.environ.get(v,"")
        if val.lower().startswith("es"): return "es"
    try:
        r=subprocess.run(["localectl","status"],capture_output=True,text=True,timeout=3)
        if "es_" in r.stdout.lower(): return "es"
    except: pass
    return "en"

LANG=detect_lang()

T={
 "es":{
  "loading":"CARGANDO...","active":"UFW ACTIVO","inactive":"UFW INACTIVO",
  "subtitle":"Gestor de Cortafuegos Ubuntu",
  "status":"Estado","allow":"Permitir","deny":"Denegar","limit":"Limitar","total":"Total",
  "nav":"Navegación","rules":"Reglas","profiles":"Perfiles","advanced":"Avanzado","log":"Registro",
  "default_policy":"Política defecto","incoming":"ENTRADA","outgoing":"SALIDA",
  "fw_rules":"Reglas del Cortafuegos","refresh":"↻ Actualizar","new_rule":"+ Nueva Regla",
  "all":"Todo","direction":"Dirección","dir_in":"Entrada","dir_out":"Salida",
  "col_action":"Acción","col_port":"Puerto","col_proto":"Proto","col_from":"Origen",
  "col_dir":"Dir","col_comment":"Comentario",
  "no_rules":"Sin reglas","loading_rules":"Cargando...",
  "sec_profiles":"Perfiles de Seguridad",
  "profiles_hint":"Aplica configuraciones preestablecidas. Requiere contraseña de administrador.",
  "web_server":"Servidor Web","web_desc":"HTTP, HTTPS y SSH limitado.",
  "dev":"Desarrollo","dev_desc":"SSH, HTTP, PostgreSQL, Redis.",
  "strict":"Máxima Seguridad","strict_desc":"Solo SSH limitado.",
  "mail":"Servidor Correo","mail_desc":"SMTP, IMAP, POP3, HTTPS.",
  "reset_ufw":"Resetear UFW","reset_desc":"Elimina TODAS las reglas.",
  "adv_title":"Configuración Avanzada","default_policy_title":"POLÍTICA POR DEFECTO",
  "incoming_traffic":"Tráfico Entrante","outgoing_traffic":"Tráfico Saliente",
  "options":"OPCIONES","event_log_label":"Registro de eventos",
  "activity_log":"Registro de Actividad","clear":"🗑 Limpiar","no_events":"Sin eventos aún",
  "new_rule_title":"// NUEVA REGLA","action":"Acción","dir_label":"Dirección",
  "both":"Ambas","port":"Puerto","protocol":"Protocolo","src_ip":"IP Origen",
  "dst_ip":"IP Destino","comment":"Comentario","desc_placeholder":"Descripción",
  "cancel":"Cancelar","add":"+ Agregar",
  "confirm_delete":"¿Eliminar regla #{}?","deleted":"Regla #{} eliminada",
  "error":"Error: {}","confirm_disable":"¿Desactivar cortafuegos?",
  "disabled":"Desactivado","enabled":"Activado",
  "confirm_reset":"¿Resetear TODO?","reset_ok":"✓ Reseteado",
  "confirm_profile":"¿Aplicar perfil {}? ({} reglas)",
  "profile_ok":"✓ Perfil {}","policy_ok":"✓ Política actualizada",
  "logging_ok":"✓ Logging actualizado","rule_ok":"✓ Regla agregada",
  "port_required":"Especifica puerto o IP",
  "login_title":"FireShield — Acceso","login_sub":"Ingresa tu contraseña de usuario",
  "password":"Contraseña","enter":"Entrar","checking":"Verificando...",
  "wrong_pass":"Contraseña incorrecta (intento {})",
  "ufw_active":"UFW ACTIVO","ufw_inactive":"UFW INACTIVO",
  "lang_btn":"EN",
 },
 "en":{
  "loading":"LOADING...","active":"UFW ACTIVE","inactive":"UFW INACTIVE",
  "subtitle":"Ubuntu Firewall Manager",
  "status":"Status","allow":"Allow","deny":"Deny","limit":"Limit","total":"Total",
  "nav":"Navigation","rules":"Rules","profiles":"Profiles","advanced":"Advanced","log":"Log",
  "default_policy":"Default policy","incoming":"INCOMING","outgoing":"OUTGOING",
  "fw_rules":"Firewall Rules","refresh":"↻ Refresh","new_rule":"+ New Rule",
  "all":"All","direction":"Direction","dir_in":"Inbound","dir_out":"Outbound",
  "col_action":"Action","col_port":"Port","col_proto":"Proto","col_from":"Source",
  "col_dir":"Dir","col_comment":"Comment",
  "no_rules":"No rules","loading_rules":"Loading...",
  "sec_profiles":"Security Profiles",
  "profiles_hint":"Apply preset configurations. Requires administrator password.",
  "web_server":"Web Server","web_desc":"HTTP, HTTPS and limited SSH.",
  "dev":"Development","dev_desc":"SSH, HTTP, PostgreSQL, Redis.",
  "strict":"Maximum Security","strict_desc":"SSH only.",
  "mail":"Mail Server","mail_desc":"SMTP, IMAP, POP3, HTTPS.",
  "reset_ufw":"Reset UFW","reset_desc":"Removes ALL rules.",
  "adv_title":"Advanced Settings","default_policy_title":"DEFAULT POLICY",
  "incoming_traffic":"Incoming Traffic","outgoing_traffic":"Outgoing Traffic",
  "options":"OPTIONS","event_log_label":"Event log",
  "activity_log":"Activity Log","clear":"🗑 Clear","no_events":"No events yet",
  "new_rule_title":"// NEW RULE","action":"Action","dir_label":"Direction",
  "both":"Both","port":"Port","protocol":"Protocol","src_ip":"Source IP",
  "dst_ip":"Destination IP","comment":"Comment","desc_placeholder":"Description",
  "cancel":"Cancel","add":"+ Add",
  "confirm_delete":"Delete rule #{}?","deleted":"Rule #{} deleted",
  "error":"Error: {}","confirm_disable":"Disable firewall?",
  "disabled":"Disabled","enabled":"Enabled",
  "confirm_reset":"Reset ALL rules?","reset_ok":"✓ Reset done",
  "confirm_profile":"Apply profile {}? ({} rules)",
  "profile_ok":"✓ Profile {}","policy_ok":"✓ Policy updated",
  "logging_ok":"✓ Logging updated","rule_ok":"✓ Rule added",
  "port_required":"Specify port or IP",
  "login_title":"FireShield — Access","login_sub":"Enter your user password",
  "password":"Password","enter":"Login","checking":"Checking...",
  "wrong_pass":"Wrong password (attempt {})",
  "ufw_active":"UFW ACTIVE","ufw_inactive":"UFW INACTIVE",
  "lang_btn":"ES",
 }
}

def tr(key,*args):
    s=T[LANG].get(key,key)
    if args:
        for i,a in enumerate(args): s=s.replace("{}",str(a),1)
    return s

HTML_TPL="""<!DOCTYPE html><html lang="__LANG__"><head><meta charset="UTF-8"><title>FireShield</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Barlow:wght@400;600;700&display=swap');
:root{--bg:#0a0c10;--surface:#0f1318;--panel:#141820;--border:#1e2530;--accent:#00e5ff;--accent2:#ff4757;--accent3:#2ed573;--warn:#ffa502;--text:#c8d6e5;--muted:#57606f;--mono:'Share Tech Mono',monospace;--sans:'Barlow',sans-serif}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--sans);min-height:100vh}
body::before{content:'';position:fixed;inset:0;background-image:linear-gradient(rgba(0,229,255,.03) 1px,transparent 1px),linear-gradient(90deg,rgba(0,229,255,.03) 1px,transparent 1px);background-size:40px 40px;pointer-events:none;z-index:0}
header{position:relative;z-index:10;display:flex;align-items:center;justify-content:space-between;padding:16px 32px;border-bottom:1px solid var(--border);background:rgba(15,19,24,.95)}
.logo{display:flex;align-items:center;gap:12px}
.logo-text{font-family:var(--mono);font-size:20px;color:var(--accent);letter-spacing:2px;text-shadow:0 0 20px rgba(0,229,255,.5)}
.logo-sub{font-size:11px;color:var(--muted);letter-spacing:3px;text-transform:uppercase}
.hright{display:flex;align-items:center;gap:12px}
.sbadge{display:flex;align-items:center;gap:8px;padding:6px 16px;border-radius:2px;font-family:var(--mono);font-size:13px;border:1px solid currentColor;cursor:pointer;letter-spacing:1px}
.sbadge.on{color:var(--accent3);background:rgba(46,213,115,.08)}
.sbadge.off{color:var(--accent2);background:rgba(255,71,87,.08)}
.sdot{width:8px;height:8px;border-radius:50%;background:currentColor;animation:pulse 2s infinite}
.sbadge.off .sdot{animation:none}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.5}}
.langbtn{font-family:var(--mono);font-size:11px;padding:5px 12px;border:1px solid var(--border);background:var(--panel);color:var(--muted);cursor:pointer;border-radius:2px;letter-spacing:2px;transition:all .15s}
.langbtn:hover{border-color:var(--accent);color:var(--accent)}
.main{display:grid;grid-template-columns:250px 1fr;height:calc(100vh - 69px)}
.sidebar{border-right:1px solid var(--border);background:var(--surface);display:flex;flex-direction:column;overflow-y:auto}
.ss{padding:18px;border-bottom:1px solid var(--border)}
.sl{font-family:var(--mono);font-size:10px;color:var(--muted);letter-spacing:3px;text-transform:uppercase;margin-bottom:14px}
.sg{display:grid;grid-template-columns:1fr 1fr;gap:7px}
.sc{background:var(--panel);border:1px solid var(--border);padding:11px;position:relative;overflow:hidden}
.sc::before{content:'';position:absolute;top:0;left:0;right:0;height:2px;background:var(--accent)}
.sc.d::before{background:var(--accent2)}.sc.s::before{background:var(--accent3)}.sc.w::before{background:var(--warn)}
.sv{font-family:var(--mono);font-size:22px;color:var(--accent);line-height:1}
.sc.d .sv{color:var(--accent2)}.sc.s .sv{color:var(--accent3)}.sc.w .sv{color:var(--warn)}
.sk{font-size:10px;color:var(--muted);letter-spacing:1px;margin-top:3px;text-transform:uppercase}
.ni{display:flex;align-items:center;gap:9px;padding:9px 11px;cursor:pointer;font-size:14px;font-weight:600;color:var(--muted);transition:all .15s;border:1px solid transparent;margin-bottom:2px;border-radius:2px}
.ni:hover{color:var(--text);background:var(--panel)}
.ni.on{color:var(--accent);background:rgba(0,229,255,.06);border-color:rgba(0,229,255,.2)}
.content{display:flex;flex-direction:column;overflow:hidden}
.ch{padding:18px 26px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.ct{font-size:17px;font-weight:700;letter-spacing:1px}
.cb{flex:1;overflow-y:auto;padding:22px 26px}
.tv{display:none}.tv.on{display:block}
.btn{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;border:1px solid var(--border);background:var(--panel);color:var(--text);font-family:var(--mono);font-size:12px;letter-spacing:1px;cursor:pointer;border-radius:2px;transition:all .15s}
.btn:hover{border-color:var(--accent);color:var(--accent)}
.btn.p{border-color:var(--accent);color:var(--accent);background:rgba(0,229,255,.06)}
.btn.p:hover{background:rgba(0,229,255,.15)}
.btn.d{border-color:var(--accent2);color:var(--accent2);background:rgba(255,71,87,.06)}
table{width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12px}
thead tr{background:var(--panel);border-bottom:2px solid var(--accent)}
thead th{padding:9px 12px;text-align:left;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--accent);font-weight:400}
tbody tr{border-bottom:1px solid var(--border)}
tbody tr:hover{background:rgba(255,255,255,.02)}
tbody td{padding:9px 12px;vertical-align:middle}
.badge{display:inline-block;padding:2px 7px;border-radius:1px;font-size:10px;letter-spacing:1px;font-weight:600;border:1px solid currentColor}
.ba{color:var(--accent3);background:rgba(46,213,115,.1)}.bd{color:var(--accent2);background:rgba(255,71,87,.1)}
.bl{color:var(--warn);background:rgba(255,165,2,.1)}.bt{color:var(--accent);background:rgba(0,229,255,.1)}
.bu{color:#a29bfe;background:rgba(162,155,254,.1)}.bx{color:var(--muted);background:rgba(87,96,111,.1)}
.ib{width:26px;height:26px;display:flex;align-items:center;justify-content:center;border:1px solid var(--border);background:transparent;color:var(--muted);cursor:pointer;border-radius:2px;font-size:11px;transition:all .15s}
.ib:hover{border-color:var(--accent2);color:var(--accent2)}
.mo{position:fixed;inset:0;background:rgba(0,0,0,.8);z-index:100;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}
.mo.on{opacity:1;pointer-events:all}
.md{background:var(--surface);border:1px solid var(--border);width:500px;max-width:95vw;transform:translateY(20px);transition:transform .2s}
.mo.on .md{transform:translateY(0)}
.mh{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;background:var(--panel)}
.mt{font-family:var(--mono);font-size:13px;color:var(--accent);letter-spacing:2px}
.mc{background:none;border:none;color:var(--muted);font-size:17px;cursor:pointer}
.mb{padding:18px}.mf{padding:12px 18px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:9px;background:var(--panel)}
.fr{display:grid;grid-template-columns:1fr 1fr;gap:11px;margin-bottom:11px}
.fg{display:flex;flex-direction:column;gap:5px}.fg.f{grid-column:1/-1}
label{font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--muted);font-family:var(--mono)}
input,select{background:var(--panel);border:1px solid var(--border);color:var(--text);padding:7px 11px;font-family:var(--mono);font-size:12px;border-radius:2px;outline:none;transition:border-color .15s}
input:focus,select:focus{border-color:var(--accent)}
select option{background:var(--panel)}
.cp{background:#060809;border:1px solid var(--border);border-left:3px solid var(--accent);padding:9px 13px;font-family:var(--mono);font-size:11px;color:var(--accent);margin-bottom:14px}
.pg{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:14px;margin-top:14px}
.pc{background:var(--panel);border:1px solid var(--border);padding:18px;cursor:pointer;transition:all .2s;position:relative;overflow:hidden}
.pc::after{content:'';position:absolute;bottom:0;left:0;right:0;height:3px;background:var(--accent);transform:scaleX(0);transition:transform .2s}
.pc:hover{border-color:var(--accent)}.pc:hover::after{transform:scaleX(1)}
.pi{font-size:26px;margin-bottom:10px}.pn{font-weight:700;font-size:14px;margin-bottom:3px}
.pd{font-size:11px;color:var(--muted);line-height:1.5}
.le{display:flex;align-items:center;gap:11px;padding:9px 0;border-bottom:1px solid var(--border);font-family:var(--mono);font-size:11px}
.lt{color:var(--muted);min-width:75px}
.tw{display:flex;align-items:center;gap:9px;padding:9px 14px;background:var(--panel);border:1px solid var(--border);border-radius:2px;margin-bottom:7px}
.tl{font-size:13px;font-weight:600}.ts{font-size:11px;color:var(--muted)}
.sw{position:relative;width:42px;height:21px;margin-left:auto}
.sw input{opacity:0;width:0;height:0}
.sl2{position:absolute;inset:0;background:var(--border);border-radius:11px;cursor:pointer;transition:.3s}
.sl2::before{content:'';position:absolute;width:15px;height:15px;left:3px;top:3px;background:var(--muted);border-radius:50%;transition:.3s}
input:checked+.sl2{background:rgba(46,213,115,.3)}
input:checked+.sl2::before{transform:translateX(21px);background:var(--accent3)}
.nt{position:fixed;bottom:22px;right:22px;z-index:200;display:none;background:var(--panel);border:1px solid var(--accent);color:var(--accent);padding:9px 18px;font-family:var(--mono);font-size:12px;border-radius:2px}
::-webkit-scrollbar{width:4px}::-webkit-scrollbar-track{background:var(--bg)}::-webkit-scrollbar-thumb{background:var(--border)}
.tb{display:flex;align-items:center;gap:11px;margin-bottom:14px;flex-wrap:wrap}.ha{display:flex;gap:7px}
</style></head><body>
<header>
  <div class="logo">
    <svg width="34" height="34" viewBox="0 0 36 36" fill="none"><path d="M18 2L4 8V18C4 25.7 10.3 32.9 18 34C25.7 32.9 32 25.7 32 18V8L18 2Z" stroke="#00e5ff" stroke-width="1.5" fill="rgba(0,229,255,0.06)"/><path d="M12 18L16 22L24 14" stroke="#00e5ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
    <div><div class="logo-text">FIRESHIELD</div><div class="logo-sub" id="subtitle">__SUBTITLE__</div></div>
  </div>
  <div class="hright">
    <button class="langbtn" onclick="toggleLang()">__LANG_BTN__</button>
    <div id="sb" class="sbadge on" onclick="toggleUFW()"><span class="sdot"></span><span id="st">__LOADING__</span></div>
  </div>
</header>
<div class="main">
  <div class="sidebar">
    <div class="ss"><div class="sl" id="lStatus">__STATUS__</div>
      <div class="sg">
        <div class="sc s"><div class="sv" id="sA">-</div><div class="sk" id="lAllow">__ALLOW__</div></div>
        <div class="sc d"><div class="sv" id="sD">-</div><div class="sk" id="lDeny">__DENY__</div></div>
        <div class="sc w"><div class="sv" id="sL">-</div><div class="sk" id="lLimit">__LIMIT__</div></div>
        <div class="sc"><div class="sv" id="sT">-</div><div class="sk" id="lTotal">__TOTAL__</div></div>
      </div>
    </div>
    <div class="ss"><div class="sl" id="lNav">__NAV__</div>
      <div class="ni on" onclick="tab('rules',this)">🛡 <span id="lRules">__RULES__</span></div>
      <div class="ni" onclick="tab('profiles',this)">📦 <span id="lProfiles">__PROFILES__</span></div>
      <div class="ni" onclick="tab('advanced',this)">⚙ <span id="lAdvanced">__ADVANCED__</span></div>
      <div class="ni" onclick="tab('log',this)">📋 <span id="lLog">__LOG__</span></div>
    </div>
    <div class="ss"><div class="sl" id="lDefPolicy">__DEFAULT_POLICY__</div>
      <div style="font-family:var(--mono);font-size:11px;line-height:2">
        <span style="color:var(--muted)" id="lIncoming">__INCOMING__:</span> <span id="pI" style="color:var(--accent2)">DENY</span><br>
        <span style="color:var(--muted)" id="lOutgoing">__OUTGOING__:</span> <span id="pO" style="color:var(--accent3)">ALLOW</span>
      </div>
    </div>
  </div>
  <div class="content">
    <div id="tv-rules" class="tv on">
      <div class="ch"><div class="ct" id="lFwRules">__FW_RULES__</div>
        <div class="ha">
          <button class="btn" onclick="load()">__REFRESH__</button>
          <button class="btn p" onclick="openM()">__NEW_RULE__</button>
        </div>
      </div>
      <div class="cb">
        <div class="tb">
          <select id="fA" onchange="render()" style="width:110px">
            <option value="">__ALL__</option>
            <option value="ALLOW">__ALLOW__</option>
            <option value="DENY">__DENY__</option>
            <option value="LIMIT">__LIMIT__</option>
          </select>
          <select id="fD" onchange="render()" style="width:110px">
            <option value="">__DIRECTION__</option>
            <option value="IN">__DIR_IN__</option>
            <option value="OUT">__DIR_OUT__</option>
          </select>
        </div>
        <table><thead><tr>
          <th>#</th><th>__COL_ACTION__</th><th>__COL_PORT__</th><th>__COL_PROTO__</th>
          <th>__COL_FROM__</th><th>__COL_DIR__</th><th>__COL_COMMENT__</th><th></th>
        </tr></thead><tbody id="rb"><tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)" id="lLoadingRules">__LOADING_RULES__</td></tr></tbody></table>
      </div>
    </div>
    <div id="tv-profiles" class="tv">
      <div class="ch"><div class="ct" id="lSecProfiles">__SEC_PROFILES__</div></div>
      <div class="cb">
        <p style="color:var(--muted);font-size:13px;margin-bottom:4px" id="lProfilesHint">__PROFILES_HINT__</p>
        <div class="pg">
          <div class="pc" onclick="prof('web')"><div class="pi">🌐</div><div class="pn" id="lWebServer">__WEB_SERVER__</div><div class="pd" id="lWebDesc">__WEB_DESC__</div></div>
          <div class="pc" onclick="prof('dev')"><div class="pi">💻</div><div class="pn" id="lDev">__DEV__</div><div class="pd" id="lDevDesc">__DEV_DESC__</div></div>
          <div class="pc" onclick="prof('strict')"><div class="pi">🔒</div><div class="pn" id="lStrict">__STRICT__</div><div class="pd" id="lStrictDesc">__STRICT_DESC__</div></div>
          <div class="pc" onclick="prof('mail')"><div class="pi">📧</div><div class="pn" id="lMail">__MAIL__</div><div class="pd" id="lMailDesc">__MAIL_DESC__</div></div>
          <div class="pc" onclick="prof('reset')" style="border-color:rgba(255,71,87,.3)"><div class="pi">🔄</div><div class="pn" id="lResetUfw">__RESET_UFW__</div><div class="pd" style="color:var(--accent2)" id="lResetDesc">__RESET_DESC__</div></div>
        </div>
      </div>
    </div>
    <div id="tv-advanced" class="tv">
      <div class="ch"><div class="ct" id="lAdvTitle">__ADV_TITLE__</div></div>
      <div class="cb">
        <div style="font-family:var(--mono);font-size:11px;letter-spacing:3px;color:var(--accent);margin-bottom:14px;padding-bottom:7px;border-bottom:1px solid var(--border)" id="lDefPolicyTitle">__DEFAULT_POLICY_TITLE__</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:11px;max-width:460px;margin-bottom:22px">
          <div class="fg"><label id="lIncomingTraffic">__INCOMING_TRAFFIC__</label><select id="aI" onchange="setDef()"><option value="deny">DENY</option><option value="allow">ALLOW</option><option value="reject">REJECT</option></select></div>
          <div class="fg"><label id="lOutgoingTraffic">__OUTGOING_TRAFFIC__</label><select id="aO" onchange="setDef()"><option value="allow">ALLOW</option><option value="deny">DENY</option><option value="reject">REJECT</option></select></div>
        </div>
        <div style="font-family:var(--mono);font-size:11px;letter-spacing:3px;color:var(--accent);margin-bottom:14px;padding-bottom:7px;border-bottom:1px solid var(--border)" id="lOptions">__OPTIONS__</div>
        <div style="max-width:460px">
          <div class="tw"><div><div class="tl" id="lEventLogLabel">__EVENT_LOG_LABEL__</div><div class="ts">/var/log/ufw.log</div></div>
            <label class="sw"><input type="checkbox" checked id="tL" onchange="setLog()"><span class="sl2"></span></label>
          </div>
        </div>
      </div>
    </div>
    <div id="tv-log" class="tv">
      <div class="ch"><div class="ct" id="lActivityLog">__ACTIVITY_LOG__</div><button class="btn" onclick="clearLog()" id="lClear">__CLEAR__</button></div>
      <div class="cb" id="lb"><div style="text-align:center;padding:60px;color:var(--muted)" id="lNoEvents">__NO_EVENTS__</div></div>
    </div>
  </div>
</div>
<div class="mo" id="mo" onclick="if(event.target===this)closeM()">
  <div class="md">
    <div class="mh"><span class="mt" id="lNewRuleTitle">__NEW_RULE_TITLE__</span><button class="mc" onclick="closeM()">✕</button></div>
    <div class="mb">
      <div id="cp" class="cp">$ sudo ufw allow 80/tcp</div>
      <div class="fr">
        <div class="fg"><label id="lAction">__ACTION__</label><select id="fAc" onchange="prev()"><option value="allow">ALLOW</option><option value="deny">DENY</option><option value="reject">REJECT</option><option value="limit">LIMIT</option></select></div>
        <div class="fg"><label id="lDirLabel">__DIR_LABEL__</label><select id="fDi" onchange="prev()"><option value="">__BOTH__</option><option value="in">IN</option><option value="out">OUT</option></select></div>
      </div>
      <div class="fr">
        <div class="fg"><label id="lPort">__PORT__</label><input type="text" id="fP" placeholder="80, 443, 8000:9000" oninput="prev()"></div>
        <div class="fg"><label id="lProtocol">__PROTOCOL__</label><select id="fPr" onchange="prev()"><option value="tcp">TCP</option><option value="udp">UDP</option><option value="">__BOTH__</option></select></div>
      </div>
      <div class="fr">
        <div class="fg"><label id="lSrcIp">__SRC_IP__</label><input type="text" id="fF" placeholder="192.168.1.0/24" oninput="prev()"></div>
        <div class="fg"><label id="lDstIp">__DST_IP__</label><input type="text" id="fT" placeholder="10.0.0.1" oninput="prev()"></div>
      </div>
      <div class="fr"><div class="fg f"><label id="lComment">__COMMENT__</label><input type="text" id="fC" placeholder="__DESC_PLACEHOLDER__" oninput="prev()"></div></div>
    </div>
    <div class="mf">
      <button class="btn" onclick="closeM()" id="lCancel">__CANCEL__</button>
      <button class="btn p" onclick="addR()" id="lAdd">__ADD__</button>
    </div>
  </div>
</div>
<div class="nt" id="nt"></div>
<script>
const API='http://127.0.0.1:__PORT__';
let rules=[],logs=[],currentLang='__LANG__';
const T=__TRANSLATIONS__;

function tr(k){return(T[currentLang]||T['en'])[k]||k}

function applyLang(){
 document.documentElement.lang=currentLang;
 document.getElementById('st').textContent=tr('loading');
 document.getElementById('subtitle').textContent=tr('subtitle');
 document.getElementById('lStatus').textContent=tr('status');
 document.getElementById('lAllow').textContent=tr('allow');
 document.getElementById('lDeny').textContent=tr('deny');
 document.getElementById('lLimit').textContent=tr('limit');
 document.getElementById('lTotal').textContent=tr('total');
 document.getElementById('lNav').textContent=tr('nav');
 document.getElementById('lRules').textContent=tr('rules');
 document.getElementById('lProfiles').textContent=tr('profiles');
 document.getElementById('lAdvanced').textContent=tr('advanced');
 document.getElementById('lLog').textContent=tr('log');
 document.getElementById('lDefPolicy').textContent=tr('default_policy');
 document.getElementById('lIncoming').textContent=tr('incoming')+':';
 document.getElementById('lOutgoing').textContent=tr('outgoing')+':';
 document.getElementById('lFwRules').textContent=tr('fw_rules');
 document.getElementById('lSecProfiles').textContent=tr('sec_profiles');
 document.getElementById('lProfilesHint').textContent=tr('profiles_hint');
 document.getElementById('lWebServer').textContent=tr('web_server');
 document.getElementById('lWebDesc').textContent=tr('web_desc');
 document.getElementById('lDev').textContent=tr('dev');
 document.getElementById('lDevDesc').textContent=tr('dev_desc');
 document.getElementById('lStrict').textContent=tr('strict');
 document.getElementById('lStrictDesc').textContent=tr('strict_desc');
 document.getElementById('lMail').textContent=tr('mail');
 document.getElementById('lMailDesc').textContent=tr('mail_desc');
 document.getElementById('lResetUfw').textContent=tr('reset_ufw');
 document.getElementById('lResetDesc').textContent=tr('reset_desc');
 document.getElementById('lAdvTitle').textContent=tr('adv_title');
 document.getElementById('lDefPolicyTitle').textContent=tr('default_policy_title');
 document.getElementById('lIncomingTraffic').textContent=tr('incoming_traffic');
 document.getElementById('lOutgoingTraffic').textContent=tr('outgoing_traffic');
 document.getElementById('lOptions').textContent=tr('options');
 document.getElementById('lEventLogLabel').textContent=tr('event_log_label');
 document.getElementById('lActivityLog').textContent=tr('activity_log');
 document.getElementById('lClear').textContent=tr('clear');
 document.getElementById('lNewRuleTitle').textContent=tr('new_rule_title');
 document.getElementById('lAction').textContent=tr('action');
 document.getElementById('lDirLabel').textContent=tr('dir_label');
 document.getElementById('lPort').textContent=tr('port');
 document.getElementById('lProtocol').textContent=tr('protocol');
 document.getElementById('lSrcIp').textContent=tr('src_ip');
 document.getElementById('lDstIp').textContent=tr('dst_ip');
 document.getElementById('lComment').textContent=tr('comment');
 document.getElementById('lCancel').textContent=tr('cancel');
 document.getElementById('lAdd').textContent=tr('add');
 document.querySelector('#mo .langbtn')&&(document.querySelector('#mo .langbtn').textContent=tr('lang_btn'));
 document.querySelector('.langbtn').textContent=tr('lang_btn');
 render();
}

function toggleLang(){
 currentLang=currentLang==='es'?'en':'es';
 applyLang();
 load();
}

async function api(p,o={}){try{const r=await fetch(API+p,o);return await r.json()}catch(e){return{ok:false,msg:String(e)}}}

async function load(){
 const d=await api('/api/status');
 const sb=document.getElementById('sb'),st=document.getElementById('st');
 if(d.active){sb.className='sbadge on';st.textContent=tr('active')}
 else{sb.className='sbadge off';st.textContent=tr('inactive')}
 rules=d.rules||[];
 document.getElementById('sA').textContent=rules.filter(r=>r.action==='ALLOW').length;
 document.getElementById('sD').textContent=rules.filter(r=>r.action==='DENY').length;
 document.getElementById('sL').textContent=rules.filter(r=>r.action==='LIMIT').length;
 document.getElementById('sT').textContent=rules.length;
 if(d.raw){
  const m1=d.raw.match(/(?:Default|Predeterminado):\s*(\w+)\s*\((?:incoming|entrantes)\)/i);
  const m2=d.raw.match(/(\w+)\s*\((?:outgoing|salientes)\)/i);
  if(m1)document.getElementById('pI').textContent=m1[1].toUpperCase();
  if(m2)document.getElementById('pO').textContent=m2[1].toUpperCase();
 }
 render();
}

function render(){
 const fa=document.getElementById('fA').value,fd=document.getElementById('fD').value;
 const f=rules.filter(r=>(!fa||r.action===fa)&&(!fd||r.direction===fd));
 const tb=document.getElementById('rb');
 if(!f.length){tb.innerHTML=`<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)">${tr('no_rules')}</td></tr>`;return}
 tb.innerHTML=f.map(r=>{
  const ab=r.action==='ALLOW'?'a':r.action==='DENY'?'d':'l';
  const[port,proto]=r.port_proto.includes('/')?r.port_proto.split('/'):[r.port_proto,''];
  return`<tr><td style="color:var(--muted)">${r.num}</td><td><span class="badge b${ab}">${r.action}</span></td><td>${port||'any'}</td><td><span class="badge b${proto?proto[0]:'x'}">${proto||'ANY'}</span></td><td style="color:${r.from!=='Anywhere'?'var(--accent)':'var(--muted)'}">${r.from}</td><td><span class="badge bx">${r.direction}</span></td><td style="color:var(--muted)">${r.comment}</td><td><button class="ib" onclick="delR('${r.num}')">✕</button></td></tr>`;
 }).join('');
}

async function delR(n){
 if(!confirm(tr('confirm_delete').replace('{}',n)))return;
 const d=await api(`/api/delete?num=${n}`);
 toast(d.ok?tr('deleted').replace('{}',n):tr('error').replace('{}',d.msg),!d.ok);
 if(d.ok)load();
}

async function toggleUFW(){
 const on=document.getElementById('sb').classList.contains('on');
 if(on){if(!confirm(tr('confirm_disable')))return;const d=await api('/api/disable');toast(d.ok?tr('disabled'):d.msg,!d.ok);if(!d.ok)return;}
 else{const d=await api('/api/enable');toast(d.ok?tr('enabled'):d.msg,!d.ok);if(!d.ok)return;}
 setTimeout(()=>load(),1500);
}

function openM(){document.getElementById('mo').classList.add('on');prev()}
function closeM(){document.getElementById('mo').classList.remove('on')}

function prev(){
 const a=document.getElementById('fAc').value,di=document.getElementById('fDi').value;
 const p=document.getElementById('fP').value,pr=document.getElementById('fPr').value;
 const f=document.getElementById('fF').value,t=document.getElementById('fT').value;
 const c=document.getElementById('fC').value;
 let cmd=`sudo ufw ${a}${di?' '+di:''}`;
 if(f)cmd+=` from ${f}`;if(t)cmd+=` to ${t}`;
 if(p)cmd+=` ${p}${pr?'/'+pr:''}`;if(c)cmd+=` comment '${c}'`;
 document.getElementById('cp').textContent='$ '+cmd;
}

async function addR(){
 const p=document.getElementById('fP').value,f=document.getElementById('fF').value;
 if(!p&&!f){toast(tr('port_required'),true);return}
 const b={action:document.getElementById('fAc').value,direction:document.getElementById('fDi').value,port:p,proto:document.getElementById('fPr').value,from:f,to:document.getElementById('fT').value,comment:document.getElementById('fC').value};
 const d=await api('/api/rule',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(b)});
 toast(d.ok?tr('rule_ok'):tr('error').replace('{}',d.msg),!d.ok);
 if(d.ok){closeM();load()}
}

const profs={
 web:[{a:'allow',p:'80',pr:'tcp',c:'HTTP'},{a:'allow',p:'443',pr:'tcp',c:'HTTPS'},{a:'limit',p:'22',pr:'tcp',c:'SSH'}],
 dev:[{a:'allow',p:'22',pr:'tcp',c:'SSH'},{a:'allow',p:'80',pr:'tcp',c:'HTTP'},{a:'allow',p:'5432',pr:'tcp',c:'PostgreSQL'},{a:'allow',p:'6379',pr:'tcp',c:'Redis'}],
 strict:[{a:'limit',p:'22',pr:'tcp',c:'SSH'}],
 mail:[{a:'allow',p:'25',pr:'tcp',c:'SMTP'},{a:'allow',p:'587',pr:'tcp',c:'Submission'},{a:'allow',p:'993',pr:'tcp',c:'IMAPS'},{a:'allow',p:'443',pr:'tcp',c:'Webmail'}]
};

async function prof(n){
 if(n==='reset'){if(!confirm(tr('confirm_reset')))return;const d=await api('/api/reset');toast(d.ok?tr('reset_ok'):d.msg,!d.ok);load();return}
 const rs=profs[n];
 if(!confirm(tr('confirm_profile').replace('{}',n).replace('{}',rs.length)))return;
 for(const r of rs)await api('/api/rule',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:r.a,port:r.p,proto:r.pr,comment:r.c,direction:'',from:'',to:''})});
 toast(tr('profile_ok').replace('{}',n));load();
}

async function setDef(){
 await api(`/api/default?dir=incoming&policy=${document.getElementById('aI').value}`);
 await api(`/api/default?dir=outgoing&policy=${document.getElementById('aO').value}`);
 toast(tr('policy_ok'));load();
}

async function setLog(){await api(`/api/logging?on=${document.getElementById('tL').checked?1:0}`);toast(tr('logging_ok'))}

function log(t,d){
 const time=new Date().toTimeString().slice(0,8);
 logs.unshift({time,t,d});if(logs.length>100)logs.pop();
 document.getElementById('lb').innerHTML=logs.map(e=>`<div class="le"><span class="lt">${e.time}</span><span class="badge bx" style="min-width:55px;text-align:center">${e.t}</span><span>${e.d}</span></div>`).join('');
}

function clearLog(){logs=[];document.getElementById('lb').innerHTML=`<div style="text-align:center;padding:60px;color:var(--muted)">${tr('no_events')}</div>`}

let tt;
function toast(m,e=false){
 const n=document.getElementById('nt');n.textContent=m;
 n.style.borderColor=e?'var(--accent2)':'var(--accent)';
 n.style.color=e?'var(--accent2)':'var(--accent)';
 n.style.display='block';clearTimeout(tt);tt=setTimeout(()=>n.style.display='none',3000);
}

function tab(t,el){
 document.querySelectorAll('.tv').forEach(x=>x.classList.remove('on'));
 document.querySelectorAll('.ni').forEach(x=>x.classList.remove('on'));
 document.getElementById('tv-'+t).classList.add('on');if(el)el.classList.add('on');
}

load();setInterval(load,10000);
</script></body></html>"""

def build_html(port, lang, translations):
    import json as _json
    t = translations[lang]
    html = HTML_TPL
    replacements = {
        "__PORT__": str(port),
        "__LANG__": lang,
        "__TRANSLATIONS__": _json.dumps(translations),
        "__SUBTITLE__": t["subtitle"],
        "__LOADING__": t["loading"],
        "__STATUS__": t["status"],
        "__ALLOW__": t["allow"],
        "__DENY__": t["deny"],
        "__LIMIT__": t["limit"],
        "__TOTAL__": t["total"],
        "__NAV__": t["nav"],
        "__RULES__": t["rules"],
        "__PROFILES__": t["profiles"],
        "__ADVANCED__": t["advanced"],
        "__LOG__": t["log"],
        "__DEFAULT_POLICY__": t["default_policy"],
        "__INCOMING__": t["incoming"],
        "__OUTGOING__": t["outgoing"],
        "__FW_RULES__": t["fw_rules"],
        "__REFRESH__": t["refresh"],
        "__NEW_RULE__": t["new_rule"],
        "__ALL__": t["all"],
        "__DIRECTION__": t["direction"],
        "__DIR_IN__": t["dir_in"],
        "__DIR_OUT__": t["dir_out"],
        "__COL_ACTION__": t["col_action"],
        "__COL_PORT__": t["col_port"],
        "__COL_PROTO__": t["col_proto"],
        "__COL_FROM__": t["col_from"],
        "__COL_DIR__": t["col_dir"],
        "__COL_COMMENT__": t["col_comment"],
        "__LOADING_RULES__": t["loading_rules"],
        "__SEC_PROFILES__": t["sec_profiles"],
        "__PROFILES_HINT__": t["profiles_hint"],
        "__WEB_SERVER__": t["web_server"],
        "__WEB_DESC__": t["web_desc"],
        "__DEV__": t["dev"],
        "__DEV_DESC__": t["dev_desc"],
        "__STRICT__": t["strict"],
        "__STRICT_DESC__": t["strict_desc"],
        "__MAIL__": t["mail"],
        "__MAIL_DESC__": t["mail_desc"],
        "__RESET_UFW__": t["reset_ufw"],
        "__RESET_DESC__": t["reset_desc"],
        "__ADV_TITLE__": t["adv_title"],
        "__DEFAULT_POLICY_TITLE__": t["default_policy_title"],
        "__INCOMING_TRAFFIC__": t["incoming_traffic"],
        "__OUTGOING_TRAFFIC__": t["outgoing_traffic"],
        "__OPTIONS__": t["options"],
        "__EVENT_LOG_LABEL__": t["event_log_label"],
        "__ACTIVITY_LOG__": t["activity_log"],
        "__CLEAR__": t["clear"],
        "__NO_EVENTS__": t["no_events"],
        "__NEW_RULE_TITLE__": t["new_rule_title"],
        "__ACTION__": t["action"],
        "__DIR_LABEL__": t["dir_label"],
        "__BOTH__": t["both"],
        "__PORT__": str(port),
        "__PROTOCOL__": t["protocol"],
        "__SRC_IP__": t["src_ip"],
        "__DST_IP__": t["dst_ip"],
        "__COMMENT__": t["comment"],
        "__DESC_PLACEHOLDER__": t["desc_placeholder"],
        "__CANCEL__": t["cancel"],
        "__ADD__": t["add"],
        "__LANG_BTN__": t["lang_btn"],
    }
    for k,v in replacements.items():
        html = html.replace(k, v)
    return html

def run_priv(cmd):
 try:
  r=subprocess.run(["sudo","-n"]+cmd,capture_output=True,text=True,timeout=60)
  return r.returncode==0,(r.stdout+r.stderr).strip()
 except subprocess.TimeoutExpired: return False,"Timeout"
 except Exception as e: return False,str(e)

def ufw_raw():
 try:
  r=subprocess.run(["sudo","-n","ufw","status","verbose"],capture_output=True,text=True,timeout=10)
  if r.returncode==0 and r.stdout.strip(): return r.stdout
  r2=subprocess.run(["systemctl","is-active","ufw"],capture_output=True,text=True,timeout=5)
  if r2.stdout.strip()=="active": return "Estado: activo\n(via systemctl)"
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
   raw=ufw_raw(); active=any(x in raw for x in ["Status: active","Estado: activo"])
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
 import gi
 for version,module in [("4.1","WebKit2"),("4.0","WebKit2"),("6.0","WebKit")]:
  try:
   if module=="WebKit2":
    gi.require_version("WebKit2",version)
    from gi.repository import WebKit2
    return "WebKit2",version,WebKit2
   else:
    gi.require_version("WebKit",version)
    from gi.repository import WebKit
    return "WebKit",version,WebKit
  except (ValueError,ImportError): continue
 return None,None,None

def check_password(password):
 try:
  import pam
  p=pam.pam()
  user=os.getenv("USER") or os.getenv("LOGNAME") or subprocess.run(["whoami"],capture_output=True,text=True).stdout.strip()
  return p.authenticate(user,password)
 except ImportError:
  try:
   user=os.getenv("USER") or subprocess.run(["whoami"],capture_output=True,text=True).stdout.strip()
   nl=chr(10)
   r=subprocess.run(["su","-c","true",user],input=password+nl,capture_output=True,text=True,timeout=5)
   return r.returncode==0
  except: return False

def show_login(Gtk, lang):
 t=T[lang]
 dlg=Gtk.Dialog(title=t["login_title"],flags=0)
 dlg.set_default_size(360,0); dlg.set_position(Gtk.WindowPosition.CENTER)
 dlg.set_deletable(False); dlg.set_resizable(False)
 box=dlg.get_content_area(); box.set_spacing(0); box.set_border_width(0)
 header=Gtk.Box(); header.set_orientation(Gtk.Orientation.VERTICAL)
 header.set_border_width(24); header.set_spacing(6)
 icon_label=Gtk.Label(); icon_label.set_markup('<span font="24">🛡</span>')
 title_label=Gtk.Label(); title_label.set_markup('<span font="16" weight="bold" foreground="#00e5ff">FIRESHIELD</span>')
 sub_label=Gtk.Label(); sub_label.set_markup(f'<span font="11" foreground="#57606f">{t["login_sub"]}</span>')
 header.pack_start(icon_label,False,False,0); header.pack_start(title_label,False,False,0); header.pack_start(sub_label,False,False,0)
 box.pack_start(header,False,False,0)
 form=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=12); form.set_border_width(24)
 entry=Gtk.Entry(); entry.set_visibility(False); entry.set_placeholder_text(t["password"]); entry.set_input_purpose(Gtk.InputPurpose.PASSWORD)
 error_label=Gtk.Label(); error_label.set_markup('<span foreground="#ff4757" font="11"> </span>')
 btn=Gtk.Button(label=t["enter"])
 form.pack_start(entry,False,False,0); form.pack_start(error_label,False,False,0); form.pack_start(btn,False,False,0)
 box.pack_start(form,False,False,0); dlg.show_all()
 result={"ok":False,"attempts":0}
 def try_login(*a):
  pwd=entry.get_text()
  if not pwd: return
  btn.set_sensitive(False); btn.set_label(t["checking"])
  while Gtk.events_pending(): Gtk.main_iteration()
  if check_password(pwd):
   result["ok"]=True; dlg.response(Gtk.ResponseType.OK)
  else:
   result["attempts"]+=1; entry.set_text("")
   error_label.set_markup(f'<span foreground="#ff4757" font="11">{t["wrong_pass"].replace("{}",str(result["attempts"]))}</span>')
   btn.set_sensitive(True); btn.set_label(t["enter"]); entry.grab_focus()
 btn.connect("clicked",try_login); entry.connect("activate",try_login)
 dlg.run(); dlg.destroy()
 return result["ok"]

def main():
 port=find_port(); url=f"http://127.0.0.1:{port}"
 html=build_html(port, LANG, T)
 server=socketserver.TCPServer(("127.0.0.1",port),make_handler(html,port))
 server.allow_reuse_address=True
 threading.Thread(target=server.serve_forever,daemon=True).start()
 signal.signal(signal.SIGINT,lambda s,f:(server.shutdown(),sys.exit(0)))
 signal.signal(signal.SIGTERM,lambda s,f:(server.shutdown(),sys.exit(0)))
 import gi
 gi.require_version("Gtk","3.0")
 from gi.repository import Gtk
 if not show_login(Gtk, LANG):
  server.shutdown(); sys.exit(0)
 webkit_module,webkit_version,WebKitLib=get_webkit_version()
 if not WebKitLib:
  print("Error: WebKit not found."); sys.exit(1)
 win=Gtk.Window(); win.set_title("FireShield — Ubuntu Firewall Manager")
 win.set_default_size(1280,800); win.set_position(Gtk.WindowPosition.CENTER)
 win.connect("destroy",Gtk.main_quit)
 # Set app icon
 import gi
 from gi.repository import GdkPixbuf
 icon_path="/usr/share/icons/hicolor/scalable/apps/fireshield.svg"
 try:
  pixbuf=GdkPixbuf.Pixbuf.new_from_file_at_size(icon_path,256,256)
  win.set_icon(pixbuf)
 except: pass
 hb=Gtk.HeaderBar(); hb.set_show_close_button(True); hb.set_title("FireShield")
 hb.set_subtitle(T[LANG]["subtitle"]); win.set_titlebar(hb)
 if webkit_module=="WebKit2":
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

echo "[2b/4] Configuring UFW permissions..."
SUDOERS_FILE="/etc/sudoers.d/fireshield"
CURRENT_USER="${SUDO_USER:-$(whoami)}"
UFW_PATH=$(which ufw 2>/dev/null || echo "/usr/sbin/ufw")
sudo tee "$SUDOERS_FILE" > /dev/null << SUDOEOF
$CURRENT_USER ALL=(ALL) NOPASSWD: $UFW_PATH
$CURRENT_USER ALL=(ALL) NOPASSWD: $UFW_PATH *
SUDOEOF
sudo chmod 0440 "$SUDOERS_FILE"
sudo visudo -c -f "$SUDOERS_FILE" 2>/dev/null && echo "   OK: $CURRENT_USER" || echo "   ERROR in sudoers"


echo "[2c/4] Installing icon..."
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps
echo "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj4KICA8cmVjdCB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgZmlsbD0iIzBhMGMxMCIgcng9IjgwIi8+CiAgPHBhdGggZD0iTTI1NiA0OEw4MCAxMjhWMjU2QzgwIDM1OCAxNjggNDQ2IDI1NiA0NzJDMzQ0IDQ0NiA0MzIgMzU4IDQzMiAyNTZWMTI4TDI1NiA0OFoiIGZpbGw9InJnYmEoMCwyMjksMjU1LDAuMDgpIiBzdHJva2U9IiMwMGU1ZmYiIHN0cm9rZS13aWR0aD0iMTYiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz4KICA8cGF0aCBkPSJNMjU2IDgwTDExMiAxNDhWMjU2QzExMiAzNDAgMTg0IDQxOCAyNTYgNDQwQzMyOCA0MTggNDAwIDM0MCA0MDAgMjU2VjE0OEwyNTYgODBaIiBmaWxsPSJyZ2JhKDAsMjI5LDI1NSwwLjA1KSIgc3Ryb2tlPSJyZ2JhKDAsMjI5LDI1NSwwLjMpIiBzdHJva2Utd2lkdGg9IjQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz4KICA8cGF0aCBkPSJNMTYwIDI1NkwyMTYgMzE2TDM1MiAxOTYiIHN0cm9rZT0icmdiYSgwLDIyOSwyNTUsMC4zKSIgc3Ryb2tlLXdpZHRoPSI1NiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBmaWxsPSJub25lIi8+CiAgPHBhdGggZD0iTTE2MCAyNTZMMjE2IDMxNkwzNTIgMTk2IiBzdHJva2U9IiMwMGU1ZmYiIHN0cm9rZS13aWR0aD0iMzYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIgZmlsbD0ibm9uZSIvPgo8L3N2Zz4=" | base64 -d | sudo tee /usr/share/icons/hicolor/scalable/apps/fireshield.svg > /dev/null
sudo mkdir -p /usr/share/pixmaps
echo "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj4KICA8cmVjdCB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgZmlsbD0iIzBhMGMxMCIgcng9IjgwIi8+CiAgPHBhdGggZD0iTTI1NiA0OEw4MCAxMjhWMjU2QzgwIDM1OCAxNjggNDQ2IDI1NiA0NzJDMzQ0IDQ0NiA0MzIgMzU4IDQzMiAyNTZWMTI4TDI1NiA0OFoiIGZpbGw9InJnYmEoMCwyMjksMjU1LDAuMDgpIiBzdHJva2U9IiMwMGU1ZmYiIHN0cm9rZS13aWR0aD0iMTYiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz4KICA8cGF0aCBkPSJNMjU2IDgwTDExMiAxNDhWMjU2QzExMiAzNDAgMTg0IDQxOCAyNTYgNDQwQzMyOCA0MTggNDAwIDM0MCA0MDAgMjU2VjE0OEwyNTYgODBaIiBmaWxsPSJyZ2JhKDAsMjI5LDI1NSwwLjA1KSIgc3Ryb2tlPSJyZ2JhKDAsMjI5LDI1NSwwLjMpIiBzdHJva2Utd2lkdGg9IjQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz4KICA8cGF0aCBkPSJNMTYwIDI1NkwyMTYgMzE2TDM1MiAxOTYiIHN0cm9rZT0icmdiYSgwLDIyOSwyNTUsMC4zKSIgc3Ryb2tlLXdpZHRoPSI1NiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIiBmaWxsPSJub25lIi8+CiAgPHBhdGggZD0iTTE2MCAyNTZMMjE2IDMxNkwzNTIgMTk2IiBzdHJva2U9IiMwMGU1ZmYiIHN0cm9rZS13aWR0aD0iMzYiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIgZmlsbD0ibm9uZSIvPgo8L3N2Zz4=" | base64 -d | sudo tee /usr/share/pixmaps/fireshield.svg > /dev/null
sudo gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
echo "[3/4] Installing launcher..."
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
GenericName=Ubuntu Firewall Manager
Comment=Graphical UFW firewall manager for Ubuntu
Exec=/usr/local/bin/fireshield
Icon=fireshield
Terminal=false
Categories=System;Settings;Security;Network;
StartupNotify=true
EOF
update-desktop-database /usr/share/applications 2>/dev/null || true
echo ""
echo "[4/4] Done! Run: fireshield"
SCRIPT_EOF
)
