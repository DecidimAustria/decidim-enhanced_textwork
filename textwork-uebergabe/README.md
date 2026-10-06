# Übergabepaket: decidim-textwork

Stand: 5. Oktober 2026

Dieses Paket enthält alles, was für den Start der Neuentwicklung vorbereitet wurde. Die Ordner sind so benannt, dass sie unverändert in das neue Repository gelegt werden können.

## Inhalt

| Datei | Zweck |
| --- | --- |
| `docs/STARTAUFTRAG.md` | Text für die erste Sitzung mit dem KI-Werkzeug |
| `docs/BAUANLEITUNG.md` | Die verbindliche Vorgabe: Datenmodell, Zuordnung zu Decidim-Bausteinen, Oberfläche, Bauschritte, Entscheidungen |
| `docs/ABWEICHUNGEN_MOCKUP.md` | Wo das Mockup vereinfacht ist und was es nicht zeigt. In diesen Punkten gilt die Bauanleitung |
| `docs/KRITERIEN.md` | Der Kriterienkatalog (20 Kriterien), auf den die Bauanleitung verweist |
| `docs/mockup/screenshots/` | Bildschirmfotos aller Zustände des Mockups, Desktop (`d-…`) und mobil (`m-…`) |
| `docs/mockup/screenshots/INDEX.md` | Welches Bild welchen Zustand zeigt und zu welchem Abschnitt der Bauanleitung es gehört |
| `docs/mockup/quelltext/` | Quelltext der beiden Mockup-Ansichten. Nur zum Nachlesen von Aufbau, Texten und Verhalten, kein Produktionscode |
| `docs/beispieldaten.yml` | Beispieldokument mit Kommentaren und Änderungsvorschlägen als Grundlage für `seeds.rb` |
| `config/locales/de.yml`, `en.yml` | Alle Texte der Oberfläche als Übersetzungsdateien |

## Was vor dem Start noch von euch kommt

1. **Repository:** Ort, Name und Lizenz des neuen Moduls.
2. **Testumgebung:** eine Decidim-0.32-Testanwendung, in die das Modul eingebunden wird, mit Ruby- und Node-Version.
3. **Übersetzungsdienst:** Klassenname eurer AWS-Anbindung (Wert von `Decidim.machine_translation_service`) und ob sie in der Testinstanz verfügbar ist.
4. **Sprachen der Präsentationsinstanz:** Originalsprache und mindestens eine zweite Sprache.
5. **Entscheidung Nr. 2** der Bauanleitung: Wörter an den Absatzsymbolen.

## Was gegenzulesen ist

- **Englische Texte** in `config/locales/en.yml` sind eine Übersetzung von Claude, nicht von einer Muttersprachlerin geprüft.
- **Schlüsselnamen** in den Übersetzungsdateien sind ein Vorschlag. Sie sollten an die Benennung im Decidim-Kern angeglichen werden, sobald das Gerüst steht.
- **Beispieldaten:** Namen in eckigen Klammern, Zahlen der Zustimmungen und die Texte der Änderungsvorschläge sind erfunden.
- **Bildschirmfotos** wurden mit einer Ersatzschrift erzeugt (Source Sans war in der Testumgebung nicht ladbar). Umbrüche können in der echten Instanz leicht anders fallen.
- **„Prüfen"-Stellen** in der Bauanleitung sind Annahmen aus dem Lesen des Decidim-Codes, nicht ausprobiert. Schritt 0 der Bauanleitung klärt sie.
