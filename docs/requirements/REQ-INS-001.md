# REQ-INS-001 — Script di installazione

**State:** Active

`install.sh`, eseguito dall'utente `droid` da un clone del repository, deve installare i pacchetti necessari, collegare i dotfile del repository nelle posizioni attese con link simbolici e attivare la sessione Hyprland. Se trova un file esistente diverso dal link atteso, deve salvarne una copia di backup prima di sostituirlo. Rieseguito su un sistema già configurato, non deve cambiare nulla né creare nuovi backup. Deve stampare un riepilogo di ciò che ha fatto. Dopo un aggiornamento dell'app Terminal che ripristina la home, rieseguire `install.sh` deve bastare per tornare alla sessione Hyprland.
