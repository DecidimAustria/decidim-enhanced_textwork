# Startauftrag für die erste Sitzung

Diesen Text als erste Nachricht an das KI-Werkzeug geben. Die Platzhalter in spitzen Klammern vorher ersetzen.

---

Du baust ein neues Decidim-Modul namens `decidim-textwork` für partizipative Textarbeit. Zielversion ist Decidim 0.32.

**Was dir zur Verfügung steht**

- Der Code von Decidim 0.32 liegt unter `<Pfad zum Decidim-Repository>`.
- Das alte Plugin `decidim-enhanced_textwork` liegt unter `<Pfad>`. Es ist nur Vorlage für Textimport und Word-Export.
- Die Testanwendung liegt unter `<Pfad>`. Tests startest du mit `<Befehl>`.
- Der Übersetzungsdienst ist `<Klassenname>` (Wert von `Decidim.machine_translation_service`).

**Lies zuerst, in dieser Reihenfolge**

1. `docs/BAUANLEITUNG.md` vollständig. Sie ist verbindlich.
2. `docs/ABWEICHUNGEN_MOCKUP.md`. Sie nennt, wo das Mockup vereinfacht ist und was es nicht zeigt. Dort gilt die Bauanleitung.
3. `docs/mockup/screenshots/INDEX.md` und die dort genannten Bilder.
4. `docs/KRITERIEN.md`.

**Dann**

1. Fasse in höchstens 15 Zeilen zusammen, was du bauen wirst und was ausdrücklich nicht. Warte auf meine Bestätigung.
2. Führe Schritt 0 der Bauanleitung aus (Erkundung) und schreibe `docs/ERKUNDUNG.md`. Baue dabei noch nichts.
3. Zeige mir die Befunde. Wenn ein Befund der Bauanleitung widerspricht, schlage eine Änderung der Bauanleitung vor, statt still davon abzuweichen.
4. Erst nach meiner Bestätigung beginnst du mit Schritt 1.

**Regeln für jede weitere Sitzung**

- Arbeite immer genau einen Bauschritt ab. Nenne am Anfang den Schritt und seine „Fertig, wenn"-Zeile.
- Bevor du eine Decidim-Schnittstelle verwendest, öffne die Datei im Decidim-Code und lies sie. Verwende nichts, was du dort nicht gefunden hast.
- Für alles, was die Bauanleitung nicht festlegt, gilt die übliche Praxis von Decidim. Vorbild ist `decidim-collaborative_texts`, danach `decidim-debates`.
- Kopiere nichts aus `decidim-proposals`.
- Jeder sichtbare Text kommt aus `config/locales/de.yml` und `en.yml`. Die Dateien im Paket sind der Ausgangspunkt; ergänze fehlende Schlüssel in beiden Sprachen.
- Am Ende jedes Schritts: Tests ausführen, Ergebnis zeigen, die „Fertig, wenn"-Zeile ausdrücklich prüfen und sagen, was du nicht prüfen konntest.
- Halte an und frage, wenn eine Entscheidung nötig ist, die in Abschnitt 9 der Bauanleitung nicht steht und nicht durch Decidim-Praxis beantwortet wird.
