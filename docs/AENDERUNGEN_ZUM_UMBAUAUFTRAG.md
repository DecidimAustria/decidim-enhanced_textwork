# Änderungen zum Umbauauftrag

Stand: 6. Oktober 2026, nach Schritt 0, Fassung 3 (alle Punkte bestätigt)

`docs/UMBAUAUFTRAG.md` bleibt unverändert. Diese Datei beantwortet die Punkte E1 bis E8 aus `docs/ERKUNDUNG.md` und nennt, was sich dadurch am Auftrag ändert. Bei Widerspruch gilt diese Datei vor dem Umbauauftrag.

Schritt 0 ist abgenommen. Schritt 1 kann beginnen.

## 1. Antworten auf die Erkundung

| Punkt | Entscheidung | Entschieden von |
| --- | --- | --- |
| **E1** Fassungen in der Vorbereitung | Fassungen und Strukturverlauf werden bis zur Veröffentlichung intern weiter geschrieben wie bisher. Ab der Veröffentlichung entstehen keine neuen Einträge. Bestehende unveränderliche Fassungen werden nicht überschrieben. | Romy |
| **E1a** „Noch keine Beteiligung“ | Maßgeblich ist der aktuelle gespeicherte Bestand, nicht die Geschichte. Kein dauerhafter Merker, keine Migration dafür. Als Beteiligung zählt jeder gespeicherte Vorschlag (auch zurückgezogen), jeder gespeicherte Kommentar (auch verborgen oder gelöscht markiert) und jede gespeicherte Zustimmung. Gibt es Beteiligung, darf das Dokument weder zurückgezogen noch bearbeitet werden. Die Sperre umfasst Text, Aufbau, Originaltitel und Originalbeschreibung. Übersetzungen dürfen weiter gepflegt werden. **Notausgang:** In den Papierkorb verschieben ist immer möglich, auch mit Beteiligung. Das Dokument ist dann nicht mehr öffentlich sichtbar, alle Rückmeldungen bleiben gespeichert. Wiederherstellen hebt die Sperre nicht auf. | Romy |
| **E2** Frist | Das Modul sperrt selbst. Siehe 2.1. | Romy |
| **E3** Bilder | Nur über den Editor, keine Bildunterschrift, keine Bilder aus Dateien. Siehe 2.4. | Romy |
| **E4** Wortvergleich | Der vorhandene Vergleich in `diff.mjs` bleibt. Übernommen werden nur Darstellungsregeln. Siehe 2.3. | Claude |
| **E5** Alternativtext | Nichts blockieren, aber Hinweis vor dem Veröffentlichen. Siehe 2.5. | Romy |
| **E6** Übersetzungen | Zusammenführen statt ersetzen. Siehe 2.6. | Vorschlag der Erkundung |
| **E7** Export | Schritt 12 umfasst ausdrücklich Datum und Zustimmungen je Vorschlag, Zustimmungen je Absatz und die Sortierung nach Zustimmung. Bilder erscheinen als Zeile „[Abbildung: Alternativtext]“. Echter Bildexport ist nicht Teil dieses Umbaus. | Vorschlag der Erkundung |
| **E8** Schalter für die Auswertung | Standardmäßig aus. Der Schalter allein hebt die Sperre veröffentlichter Texte nicht auf. Vorhandene Entscheidungen und Fassungen bleiben gespeichert und werden nicht zurückgesetzt. Die Aktivierung der Auswertung ist ein eigener späterer Auftrag. | Romy |

Weitere Befunde der Erkundung, die übernommen werden:

- **Gem und Branch:** Es bleibt beim Gem `decidim-enhanced_textwork` und beim Branch `feature/textwork-redesign`. Wo der Umbauauftrag `decidim-textwork` schreibt, ist dieses Gem gemeint.
- **Bestehende Daten:** Kapitel-Zustimmungen und Kapitel-Abonnements bleiben gespeichert und werden weder umgedeutet noch gelöscht. Sie werden in der neuen Oberfläche nicht angezeigt und nicht mitgezählt.
- **Vorhandene Zustimmungen zum eigenen Vorschlag:** Sie bleiben gespeichert und zählen weiter in der Zahl des Vorschlags. Neue sind verboten. Wer eine solche Zustimmung hat, kann sie zurücknehmen, solange Schalter und Frist Zustimmungen erlauben; sonst niemand. In der Karte steht dafür beim eigenen Vorschlag neben „N Zustimmungen“ der Link „Eigene Zustimmung zurücknehmen“, nur wenn eine vorhanden ist. Solche Zustimmungen konnten nur im bisherigen Redesign-Stand entstehen, also in Test- und Vorführinstanzen.
- **Nur ein Kommentarbereich gleichzeitig:** Wie bisher ist in Leiste und Blatt immer nur eine Kommentarressource eingehängt. Das passt zum Auftrag, weil Absatzliste und Vorschlagsdetail einander ersetzen.

## 2. Was sich am Umbauauftrag ändert

### 2.1 Frist (ändert 5.1, 5.4, 5.14, Schritte 3 und 11)

Bisher: Das Datum ist eine Anzeige, gesperrt wird über die Schalter je Phase.

Neu: Eine Handlung ist erlaubt, wenn ihr Schalter sie nicht sperrt **und** das Enddatum der aktiven Phase nicht überschritten ist.

- Maßgeblich ist das Ende des genannten Tages in der Zeitzone der Organisation. Steht dort „31.10.“, ist am 31.10. um 23:59 noch alles möglich, am 1.11. um 00:00 nicht mehr. Verglichen wird das lokale Datum der Organisation mit dem Enddatum, nicht eine Stundenzahl. Die Regel ermittelt die Zeitzone ausdrücklich aus der Organisation, damit sie auch außerhalb eines Controllers stimmt.
- Die Regel sitzt an einer Stelle im Modul und gilt für diese Schreibwege: Vorschlag anlegen, bearbeiten und zurückziehen; Zustimmung geben und zurücknehmen; Kommentar anlegen, bearbeiten und bewerten. Sie muss auch die allgemeinen Wege des Kerns abdecken, nicht nur die eigene Oberfläche. Die Erkundung hat gezeigt, dass Likes, Folgen und Kommentare im Kern über verschiedene Berechtigungsketten laufen; die Anbindung bleibt auf Ressourcen von Textwork begrenzt und ändert keine Datei des Kerns.
- **Nicht gesperrt** werden durch Frist und Schalter: das Folgen des Dokuments und dessen Beenden (wer nach dem Stichtag folgt, will erfahren, wie es weitergeht) und das Löschen des eigenen Kommentars (wer seinen Beitrag zurückziehen will, kann das immer). Melden bleibt ebenfalls möglich.
- Hat die aktive Phase kein Enddatum oder der Beteiligungsraum keine Phasen, gibt es keine Datumssperre und keine Fristanzeige.
- Nach Ablauf verhält sich die Seite wie in 5.14 beschrieben: lesbar, ohne Schaltflächen zum Mitmachen, im Überblick „Die Sammelphase ist beendet. Die Rückmeldungen werden ausgewertet.“
- Verlängern Verantwortliche das Enddatum oder aktivieren sie eine neue Phase, ist die Beteiligung wieder offen.

*Fertig, wenn* zusätzlich zu Schritt 11 ein Test mit gestellter Uhr zeigt: Am Enddatum ist alles möglich, am Tag danach wird jeder der genannten Schreibwege abgewiesen, auch über die Endpunkte des Kerns.

### 2.2 Zustimmung: Wege des Kerns (ergänzt 5.5, 5.6, Schritt 2)

Die Erkundung hat gezeigt, dass `POST /likes` des Kerns für einen Absatz heute mit `NoMethodError: likes_enabled` abbricht und dass der Kern weder `Block#likeable?` noch die Autorengleichheit prüft.

- `likes_enabled` in den Phaseneinstellungen so bereitstellen, wie die Berechtigungen des Kerns es erwarten.
- Die Regeln des Moduls gelten auch über die allgemeinen Endpunkte des Kerns: Zustimmung nur zu Absätzen und zu Vorschlägen, nie zu Überschriften, Bildern oder dem eigenen Vorschlag; Folgen nur für das Dokument.
- Keine Änderung am Controller des Kerns. Die Prüfung gehört in die Berechtigungen des Moduls.

*Fertig, wenn* zusätzlich zu Schritt 2 Tests zeigen: Eine Zustimmung über den Endpunkt des Kerns gelingt für einen Absatz und einen fremden Vorschlag und wird für Überschrift, Bild und eigenen Vorschlag sauber abgewiesen, ohne Programmfehler.

### 2.3 Wortvergleich (ersetzt 5.9 in Teilen, ändert Schritt 6)

Bisher: `docs/referenz/wortvergleich.js` ist die Vorlage, die bisherige Markierung wird ersetzt.

Neu: Der vorhandene Vergleich in `diff.mjs` bleibt die Grundlage, mit seiner verlustfreien Zerlegung, der Behandlung von Satzzeichen und Zeilenumbrüchen und der Laufzeitgrenze. Die Vorlage im ersten Paket war an drei Stellen schlechter: Sie zeigte reine Satzzeichenänderungen nicht an, behandelte Windows-Zeilenumbrüche als Änderung und hatte keine Laufzeitgrenze.

Aus 5.9 gelten weiter, als Darstellungsregeln auf dem Ergebnis von `diff.mjs`:

- Je geänderter Stelle steht erst alles Gestrichene, dann alles Eingefügte. Nie abwechselnd Wort für Wort.
- Großer Umbau: mehr als drei geänderte Stellen, oder mehr als fünf Wörter und zugleich mehr als die Hälfte des Originals betroffen. Dann „Bisher“ und „Vorschlag“ untereinander statt Wortmarkierung. Die Schwellen sind Darstellungsregeln, keine Validierung.
- Kurze Absätze ganz zeigen, lange auf Umgebung kürzen.
- Markierung ohne Leerzeichen am Rand, `<del>` und `<ins>`, nie nur über Farbe.
- Eine Umsetzung im Browser für Karte, Detail und Vorschau. Ohne JavaScript „Bisher“ und „Vorschlag“ als Text.

Aus 5.9 gilt nicht mehr:

- „Satzzeichen am Wortende zählen nicht als Änderung.“ Jede Änderung ist sichtbar, auch ein einzelnes Satzzeichen. Ob dabei nur das Zeichen oder das ganze Wort markiert wird, bestimmt die Zerlegung von `diff.mjs`.

Neu dazu:

- Zeilenumbrüche vor dem Vergleich vereinheitlichen (CRLF zu LF). Gespeichert wird der Vorschlag unverändert.
- „Vorschlag einreichen“ ist gesperrt, wenn sich Original und Vorschlag nur in Leerzeichen oder in der Art des Zeilenumbruchs unterscheiden. Eine reine Satzzeichenänderung ist eine Änderung.

`docs/referenz/wortvergleich.js` und `docs/WORTVERGLEICH_BEISPIELE.md` liegen in diesem Nachtrag in neuer Fassung bei. Die Referenz ist jetzt nur noch eine Veranschaulichung der Darstellungsregeln. Die Beispieldatei hat neun Fälle; verbindlich ist dort jeweils die Zeile „Muss gelten“.

*Fertig, wenn* (ersetzt die Zeile von Schritt 6) die neun Fälle als automatische Tests gegen die Zeile „Muss gelten“ bestehen, die bisherigen Tests zu Verlustfreiheit und Laufzeitgrenze weiter bestehen und die Karte ohne JavaScript „Bisher“ und „Vorschlag“ zeigt.

### 2.4 Bilder (ersetzt 5.11 in Teilen, ändert Schritt 9)

**Eingabe.** Bilder kommen ausschließlich über den Bild-Upload des Decidim-Editors im Admin-Bereich.

- Den Editor so einrichten, dass das Bildwerkzeug verfügbar ist und Video nicht. Geht das nur über die Werkzeugleiste `full`, werden Videoinhalte beim Import nicht übernommen und die Admin erhält einen Hinweis.
- Bilder aus hochgeladenen Dateien (Word, ODT, Markdown) werden nicht übernommen. Enthält die Datei Bilder, steht nach dem Import ein Hinweis: „N Bilder aus der Datei wurden nicht übernommen. Bilder fügen Sie über den Editor ein.“ Lässt sich die Zahl nicht mit geringem Aufwand bestimmen, genügt der Hinweis ohne Zahl oder er entfällt.
- Fremde Bildadressen werden nie serverseitig abgerufen. Ein Bild, das nicht aus dem Upload des Kerns stammt, wird nicht übernommen.
- Der Import übernimmt keine Breitenangaben des Editors und verliert keine Bilder in umschließenden Knoten oder Links. Ein Link um ein Bild wird nicht übernommen.

**Speicherung.** Der Bildbaustein verweist dauerhaft auf die hochgeladene Datei des Kerns (`Decidim::EditorImage` und ihr Anhang), nicht nur auf eine Adresse. Der Alternativtext aus dem Editor-HTML wird am Baustein gespeichert. Dafür ist eine zusätzliche Migration vorgesehen.

**Keine Bildunterschrift.** Es gibt kein Feld dafür und keine Ausgabe. Unter dem Bild steht rechtsbündig nur der Link „Vergrößern“. In der vergrößerten Ansicht steht nur das Bild.

**Auslieferung.** Abweichend von der ersten Absprache nicht das Original im Fließtext: Der Kern lässt Bilder bis 3840 px Kantenlänge und in der geprüften Instanz bis 10 MiB zu und erzeugt keine verkleinerten Fassungen. Deshalb:

- Für die Darstellung im Text eine eigene verkleinerte Fassung über die Varianten von ActiveStorage, längere Kante höchstens 1600 px, nie größer als das Original.
- Für „Vergrößern“ das Original.
- Die Größenregel aus 5.11 (`max-width`, `max-height`, kein Hochziehen, mittig) gilt unverändert.

Von Romy am 6. Oktober 2026 bestätigt.

Der Rest von 5.11 gilt weiter: eigener Baustein ohne Nummer, ohne Beteiligung, nicht im Inhaltsverzeichnis, nur vor der Veröffentlichung, Teilung eines Absatzes an der Stelle des Bildes.

*Fertig, wenn* (ergänzt Schritt 9) ein über den Editor hochgeladenes Bild nach dem Import als Baustein mit gespeichertem Alternativtext vorliegt, der Baustein nach dem Löschen des Editor-Inhalts weiter angezeigt wird, ein Video nicht übernommen wird und im Text die verkleinerte Fassung, in der Vergrößerung das Original geladen wird.

### 2.5 Alternativtext (ergänzt 5.11, Schritt 9)

Es bleibt dabei: Feld, Beschriftung und Speicherung kommen vom Kern, nichts wird blockiert, fehlender Text ergibt `alt=""`.

Neu: ein Hinweis im Admin-Bereich vor dem Veröffentlichen. Er nennt Bilder, deren Alternativtext leer ist oder dem Dateinamen entspricht. Der Kern füllt das Feld mit dem aufbereiteten Dateinamen vor; ein solcher Text gilt als nicht beschrieben.

- Wortlaut: „N Bilder haben noch keine Beschreibung. Menschen, die das Bild nicht sehen, erfahren dann nicht, was es zeigt.“
- Darunter je Bild eine kleine Vorschau und ein Feld zum Nachtragen, damit niemand zurück in den Editor muss.
- „Trotzdem veröffentlichen“ bleibt möglich.
- Ein leerer Alternativtext ist für reine Schmuckbilder richtig. Der Hinweis ist deshalb eine Erinnerung, kein Fehler.

### 2.6 Übersetzungsdateien (ersetzt Regel 3.6, ändert Schritte 3 und 13)

Bisher: Die Dateien im Paket ersetzen die bisherigen Schlüssel, fehlende werden entfernt.

Neu: Die Schlüssel aus dem Paket werden mit den vorhandenen Dateien zusammengeführt.

- Ersetzt werden nur die Schlüssel der Sammel-Oberfläche für Teilnehmende.
- Erhalten bleiben: Admin-Texte, Ereignisse und Benachrichtigungen, Titel der Ressourcen, Validierungs- und Fallbacktexte, Leerzustände und alle Texte der abgeschalteten Auswertung.
- Schritt 13 entfernt nur Schlüssel der alten Bedienung für Teilnehmende. Unbenutzte Schlüssel der Auswertung bleiben.

Gegenüber `config/locales/de.yml` aus dem ersten Paket:

Entfällt:

```yaml
decidim.textwork.comments.show_all
```

Neu, deutsch:

```yaml
de:
  decidim:
    textwork:
      admin:
        images:
          missing_description:
            one: "1 Bild hat noch keine Beschreibung. Menschen, die das Bild nicht sehen, erfahren dann nicht, was es zeigt."
            other: "%{count} Bilder haben noch keine Beschreibung. Menschen, die das Bild nicht sehen, erfahren dann nicht, was sie zeigen."
          description_label: Was ist auf dem Bild zu sehen?
          publish_anyway: Trotzdem veröffentlichen
        import:
          images_skipped: Bilder aus der Datei wurden nicht übernommen. Bilder fügen Sie über den Editor ein.
          video_skipped: Videos werden nicht übernommen.
        documents:
          locked: Dieses Dokument ist veröffentlicht. Text und Aufbau lassen sich nicht mehr ändern.
          locked_has_feedback: Zu diesem Dokument gibt es bereits Rückmeldungen. Es lässt sich nicht mehr zurückziehen oder ändern. In den Papierkorb verschieben ist weiter möglich.
      suggestions:
        unlike_own: Eigene Zustimmung zurücknehmen
```

Neu, englisch (von Claude übersetzt, nicht von einer Person mit englischer Muttersprache gelesen):

```yaml
en:
  decidim:
    textwork:
      admin:
        images:
          missing_description:
            one: "1 image has no description yet. People who cannot see the image will not learn what it shows."
            other: "%{count} images have no description yet. People who cannot see the images will not learn what they show."
          description_label: What does the image show?
          publish_anyway: Publish anyway
        import:
          images_skipped: Images from the file were not imported. Add images using the editor.
          video_skipped: Videos are not imported.
        documents:
          locked: This document is published. Its text and structure can no longer be changed.
          locked_has_feedback: This document has already received feedback. It can no longer be unpublished or changed. Moving it to the trash is still possible.
      suggestions:
        unlike_own: Withdraw your own agreement
```

### 2.7 Kommentare (ändert 5.10)

Die Liste der Kommentare wird nicht auf drei gekürzt. Das Nachladen des Kerns bleibt unverändert. Der Satz „Lässt sich die Liste mit geringem Aufwand …“ entfällt. Gekürzt werden nur die Vorschläge (drei, dann „Alle N Änderungsvorschläge anzeigen“).

Die Sortier-Auswahl wird wie von der Erkundung vorgeschlagen über eine Kennzeichnung nach Kommentarzahl und ein Stylesheet ausgeblendet. Die Kennzeichnung wird nach dem Absenden und nach dem Nachladen aktualisiert.

### 2.8 Zusätzliche Hinweise zur Reihenfolge

Die folgenden Punkte ändern den Auftrag nicht, sondern stellen ihn klar:

- **Alte Bedienung früh entfernen.** Was in 4.2 unter „entfällt“ steht, verschwindet in dem Schritt, der es ersetzt, im Wesentlichen in den Schritten 3 bis 7. Schritt 13 räumt nur Reste auf. Alte und neue Bedienung sollen nicht nebeneinander bestehen.
- **Mobil gehört zu jedem Oberflächenschritt.** Die Schritte 3, 5, 7, 8 und 9 sind erst fertig, wenn auch das Blatt bei 390 px geprüft ist. Dazu gehört, dass ein Tipp auf den Absatztext das Blatt öffnet; die Sperre in `paragraph()` entfällt in Schritt 5.
- **Escape schließt eine Ebene, nicht das ganze Panel.** Der Bestand schließt alles auf einmal. Das wird in den Schritten 5 bis 8 mitgebaut und in Schritt 10 geprüft.

## 3. Dateien in diesem Nachtrag

| Datei | Was damit zu tun ist |
| --- | --- |
| `docs/AENDERUNGEN_ZUM_UMBAUAUFTRAG.md` | Diese Datei. Neben den Umbauauftrag legen. |
| `docs/WORTVERGLEICH_BEISPIELE.md` | Ersetzt die Datei aus dem ersten Paket. |
| `docs/referenz/wortvergleich.js` | Ersetzt die Datei aus dem ersten Paket. |
| `docs/mockup/screenshots/` | Ersetzt den Ordner aus dem ersten Paket. Gleiche Dateinamen, neuer Stand: keine Bildunterschrift, Satzzeichenänderungen sichtbar, Kommentare ungekürzt. |
| `docs/mockup/quelltext/` | Ersetzt den Ordner aus dem ersten Paket. |

Unverändert und weiter gültig: `docs/UMBAUAUFTRAG.md`, `docs/STARTAUFTRAG.md`, `config/locales/de.yml` und `en.yml` (mit den Änderungen aus 2.6).

## 4. Stand der Bestätigungen

Von Romy am 6. Oktober 2026 bestätigt:

- E1, E1a mit Notausgang Papierkorb, E2, E3, E5, E8.
- Folgen bleibt nach dem Stichtag möglich; eigene Kommentare lassen sich nach dem Stichtag löschen, aber nicht bearbeiten (2.1).
- Das Ende des Tages in der Zeitzone der Organisation als Zeitpunkt der Sperre (2.1).
- Die verkleinerte Fassung für Bilder im Text, das Original beim Vergrößern (2.4).
- Der Umgang mit vorhandenen Zustimmungen zum eigenen Vorschlag (Abschnitt 1).
- Die Schwellen aus dem Umbauauftrag als Startwerte: 660 px, drei Vorschläge, großer Umbau, Bildhöhe. Sie werden nach dem Bau am echten Bildschirm geprüft und bei Bedarf angepasst.

Damit ist in diesem Nachtrag nichts mehr offen.

Hinweis: `README.md` und `STARTAUFTRAG.md` aus dem ersten Paket nennen noch sieben Testfälle und das Ersetzen der Übersetzungsdateien. Dieser Nachtrag geht vor.
