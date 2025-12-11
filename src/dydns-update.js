#!/usr/bin/env node
require("dotenv").config();
const axios = require("axios");

// These are the credentials for the dedicated DynDNS user
// that you create in the INWX Web-Interface under "DynDNS".
const INWX_DYNDNS_USER = process.env.INWX_USER;
const INWX_DYNDNS_PASS = process.env.INWX_PASS;

const UPDATE_URL = "https://dyndns.inwx.com/nic/update";

async function getPublicIP(version = 4) {
    const url = version === 6 
        ? "https://api6.ipify.org?format=json"
        : "https://api.ipify.org?format=json";
    
    try {
        const res = await axios.get(url, { timeout: 5000 }); // 5 second timeout
        return res.data.ip;
    } catch (err) {
        // It's common to not have an IPv6 address, so we'll just log this as info.
        if (version === 6) {
            console.log(`[INFO] Keine IPv6-Adresse gefunden oder Dienst nicht erreichbar.`);
        } else {
            console.error(`[ERROR] Fehler beim Ermitteln der IPv${version}-Adresse:`, err.message);
        }
        return null; // Return null if fetching fails
    }
}

async function updateDynDNS() {
    if (!INWX_DYNDNS_USER || !INWX_DYNDNS_PASS) {
        console.error("[ERROR] INWX_USER oder INWX_PASS sind in der .env-Datei nicht gesetzt.");
        process.exit(1);
    }

    try {
        // Fetch both IPs in parallel
        const [ip4, ip6] = await Promise.all([
            getPublicIP(4),
            getPublicIP(6)
        ]);

        if (!ip4 && !ip6) {
            console.error("[ERROR] Konnte weder eine IPv4- noch eine IPv6-Adresse ermitteln.");
            process.exit(1);
        }

        const params = {};
        if (ip4) {
            params.myip = ip4;
            console.log(`[INFO] Gefundene IPv4: ${ip4}`);
        }
        if (ip6) {
            params.myipv6 = ip6;
            console.log(`[INFO] Gefundene IPv6: ${ip6}`);
        }
        
        console.log("[INFO] Sende Update an INWX...");
        const response = await axios.get(UPDATE_URL, {
            params,
            auth: {
                username: INWX_DYNDNS_USER,
                password: INWX_DYNDNS_PASS,
            },
        });

        console.log(`[INFO] INWX Antwort: ${response.data}`);

        if (response.data.startsWith("good") || response.data.startsWith("nochg")) {
            console.log("[OK] DynDNS Update erfolgreich.");
        } else {
            console.error("[ERROR] DynDNS Update fehlgeschlagen.");
        }
    } catch (err) {
        if (err.response) {
            console.error(`[ERROR] Server-Fehler: ${err.response.status} ${err.response.statusText}`);
            console.error(`[ERROR] Server-Antwort: ${err.response.data}`);
        } else {
            console.error("[ERROR] Ein unerwarteter Fehler ist aufgetreten:", err.message);
        }
        process.exit(1);
    }
}

updateDynDNS();