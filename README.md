# Surface Urban Heat Island Intensity (SUHII) Mapping

`🇮🇹 Versione italiana sotto (Italian version below)`

This repository contains tools for automating the production of surface urban heat island (SUHII) maps from satellite imagery and OpenStreetMap data. The workflow centres on the `src/R/SUHI_mapping.R` script, which orchestrates preprocessing, spatial analysis, and visualization tasks. Complementary Python utilities (such as `downloader.py`) support data acquisition.

## IMPORTANT: After using the tool, share your feedback and help us grow this project!  
We would love to hear how you are using the workflow! Your contribution helps us improve the tools and enhance practical applications.  
We are building SUHII_mapping as an open, useful tool that is truly rooted in the needs of the community.
That is why we have created a short form: filling it out helps us improve the code, understand how it is used and, above all, give a voice to those who participate.  
Our goal is to create grassroots practices, a bridge between science and citizenship, where researchers, professionals, students, administrators and curious minds can contribute together to the public good.
At the same time, we are also developing a web platform to facilitate connections between users, offer more accessible tools and create a space for ongoing discussion.  
  
Filling out the form means:  
🛠️ telling us what works and what we can improve  
🌍 contributing to an open and participatory process of knowledge  
💬 helping us shape the space for dialogue we are creating  

If you want to contribute to the project — with code, ideas, feedback or collaborations — you are welcome!

👉 Fill out the [feedback form](https://docs.google.com/forms/d/e/1FAIpQLScuYIyojP9iiTP3vjk2wFNVpeEuBwITrGmT-Cp-hU-JH-i7mw/viewform?usp=sf_link) to share your experience. Your ideas matter!  

If you wish, you can also tell us your user story and the impact of your results. Thank you for contributing.

## Prerequisites

### Installation 
1. Download the latest stable release of [R](https://cran.r-project.org/) for your operating system. Follow the platform-specific installer prompts (Windows `.exe`, macOS `.pkg`, or Linux package manager instructions).
3. Install [RStudio](https://posit.co/download/rstudio-desktop/) for an enhanced development environment.
4. Install [Rtools](https://cran.r-project.org/bin/windows/Rtools/) (Windows only). If you’re on Windows, install Rtools to enable the compilation of R packages that require source building.
5. Ensure you have Python v3.x installed. (Windows: Install via the Microsoft Store; macOS / Linux: Use your system package manager or download from [python.org](https://www.python.org/)). Make sure that Python is added to your PATH (environment variables) so it can be accessed from the command line.

### Install Required R Packages  
All required R packages will be installed automatically the first time you run the workflow.
This process may take several minutes depending on your connection speed — please be patient and allow it to complete.  

## Using the R Workflow

1. **Download or clone the repository**
   ```bash
   git clone https://github.com/Officina-SCIFT/SUHII_mapping.git
   cd SUHII_mapping
   ```

2. **Prepare configuration**
   Open `src/R/SUHI_mapping.R` with RStudio and edit the configuration block near the top of the script:
   - `citta`: name of the city or study area.
   - `percorso`: working directory where data are processed and outputs will be stored.
   - `LD_script`: path to the folder that contains `downloader.py`.

3. **Run the script**
   Select all the script code and launch it (**Run** button).
   
   The script will:
   - Install and load required packages.
   - Query OpenStreetMap features by dividing the area of interest into manageable chunks.
   - Download, preprocess, and mosaic satellite imagery using the configured parameters.
   - Generate maps and intermediate datasets inside the working directory defined by `percorso`.


## 🎥 Video tutorial
You can watch the demo video here:  
👉 [Click to view on Google Drive](https://drive.google.com/file/d/1ZS2OnfOAX6Wq26X5Xw3clab8kQVoOQq1/view?usp=sharing)


## Disclaimer
All data products and derived outputs provided in this repository are based on the associated peer‐reviewed publication. Any use of these data - whether for further analysis, modeling, visualization, or incorporation into other projects - must include a citation to the original paper.
Please cite the following reference when using any portion of these data:

Richiardi, C., Caroscio, L., Crescini, E., De Marchi, M., De Pieri, G. M., Ceresi, C., Baldo, F., Francobaldi, M., & Pappalardo, S. E. (2025). A global downstream approach to mapping surface urban heat islands using open data and collaborative technology. *Sustainable Geosciences: People, Planet and Prosperity*, 100006. [https://doi.org/10.1016/j.susgeo.2025.100006](https://doi.org/10.1016/j.susgeo.2025.100006).

Failure to cite the original publication may constitute a breach of academic and professional standards.

## Project 
The project aligns with SDG 17 (Partnerships for the Goals) by fostering open, cross-sectoral collaboration through open science principles. By releasing the workflow under the GNU General Public License v3.0 (GPL 3.0) and providing implementations in both R and Python, the project promotes inclusivity in technical development and downstream use.

In line with the values of transparency, reproducibility, and accessibility, all code, data processing steps, and documentation are openly shared to facilitate collaboration across research institutions, policy sectors, and geographic regions. The repository is intended as a living resource that encourages community contributions, interoperability between tools, and the co-creation of robust environmental analyses supporting evidence-based decision-making.
  
## Acknowledgements
The development of this workflow was made possible thanks to the collaboration and support of **SCIFT Officina**.

For questions or contributions, please open an issue or submit a pull request.

# 💬 Share Your Feedback
We’d love to hear how you’re using the workflow. Your input helps improve the workflow and highlight real-world applications.  
👉 Take a few minutes to fill out our [user feedback form](https://docs.google.com/forms/d/e/1FAIpQLScPsFdDerNaYa_WPHlRN-0qV5SfJcZ4uILIQK0cef_2M6jNOg/viewform?usp=dialog).

If you’d like, you can also share your story about how you used the workflow and the impact of your results.
Thank you for helping make this project more open, useful, and collaborative! 🌍

-------------------------------------------------------------------------------------------------------------------------------------------------------
  
# Mappatura dell'intensità delle isole di calore urbane superficiali (SUHII)  

(Versione italiana)

Questa repository contiene strumenti per automatizzare la produzione di mappe dell’intensità dell’isola di calore urbana superficiale (Surface Urban Heat Island Intensity, SUHII) a partire da immagini satellitari e dati di OpenStreetMap.
Il flusso di lavoro è centrato sullo script src/R/SUHI_mapping.R, che gestisce le operazioni di pre-processing, analisi spaziale e visualizzazione.
Utilità complementari in Python (come downloader.py) supportano l’acquisizione dei dati.

# IMPORTANTE: Condividi il tuo feedback e aiutaci a far crescere questo progetto!  

Ci piacerebbe sapere come stai utilizzando il workflow! Il tuo contributo aiuta a migliorare gli strumenti e a valorizzare le applicazioni pratiche.  
Stiamo costruendo SUHII_mapping come uno strumento aperto, utile e realmente radicato nelle esigenze della comunità.  
Per questo abbiamo creato un breve form: compilarlo ci aiuta a migliorare il codice, a capire come viene utilizzato e, soprattutto, a dare voce a chi partecipa.  
Il nostro obiettivo è creare pratiche dal basso, un ponte tra scienza e cittadinanza, dove ricercatori, professionisti, studenti, amministratori e curiosi possano contribuire insieme al bene pubblico.  
In parallelo stiamo anche sviluppando una piattaforma web per facilitare la connessione tra utenti, offrire strumenti più accessibili e creare uno spazio di confronto continuo.

Compilare il form significa:
🛠️ indicarci cosa funziona e cosa possiamo migliorare
🌍 contribuire a un processo aperto e partecipato di conoscenza
💬 aiutarci a modellare lo spazio di dialogo che stiamo creando

Se vuoi contribuire al progetto - con codice, idee, feedback o collaborazioni — sei benvenutə!

👉 Compila il [modulo di feedback](https://docs.google.com/forms/d/e/1FAIpQLScuYIyojP9iiTP3vjk2wFNVpeEuBwITrGmT-Cp-hU-JH-i7mw/viewform?usp=sf_link) per condividere la tua esperienza. Le tue idee contano!

Se vuoi, puoi anche raccontarci la tua storia d’uso e l’impatto dei tuoi risultati. Grazie per contribuire a rendere questo progetto più aperto, utile e collaborativo! 🌍

## Prerequisiti    

### Installazione   
1. Scarica l’ultima versione stabile di [R](https://cran.r-project.org/) per il tuo sistema operativo. Segui le istruzioni dell’installer specifico per la tua piattaforma (Windows .exe, macOS .pkg, oppure tramite il gestore pacchetti su Linux).
2. Installa [RStudio](https://posit.co/download/rstudio-desktop/) per un ambiente di sviluppo più user-friendly.
3. Installa [Rtools](https://cran.r-project.org/bin/windows/Rtools/) (solo per Windows) per permettere la compilazione dei pacchetti R da sorgente.
4. Assicurati di avere installato Python v3.x. Windows: installa tramite Microsoft Store; macOS / Linux: utilizza il gestore pacchetti di sistema oppure scarica da [python.org](https://www.python.org/); Verifica che Python sia incluso nella variabile d’ambiente PATH in modo da poterlo richiamare da linea di comando.

### Installazione dei pacchetti R richiesti

Tutti i pacchetti R necessari verranno installati automaticamente al primo avvio del workflow.
Il processo può richiedere alcuni minuti a seconda della velocità della connessione — attendi fino al completamento.

## Utilizzo del workflow in R  
  
1. **Clona o scarica la repository**
   ```bash
   git clone https://github.com/Officina-SCIFT/SUHII_mapping.git
   cd SUHII_mapping
   ```
     
2. **Configura lo script**  
   Apri `src/R/SUHI_mapping.R` in RStudio ed edita il blocco di configurazione vicino all’inizio dello script:
   - `citta`: ome della città o area di studio.  
   - `percorso`: directory di lavoro dove verranno salvati i dati elaborati e gli output.   
   - `LD_script`: percorso della cartella contenente il file `downloader.py`.

3. **Esegui lo script**  
   Seleziona tutto il codice e avvialo (pulsante **Run**).  
     
   Lo script eseguirà automaticamente:    
   - l’installazione e il caricamento dei pacchetti necessari;  
   - l’interrogazione di OpenStreetMap suddividendo l’area di interesse in porzioni gestibili;  
   - il download, il pre-processing e il mosaicking delle immagini satellitari secondo i parametri configurati;  
   - la generazione delle mappe finali e dei dataset intermedi all’interno della directory specificata in `percorso`.  

## Disclaimer

Tutti i prodotti di dati e gli output derivati forniti in questa repository si basano sulla pubblicazione scientifica associata e revisionata.
Qualsiasi utilizzo di questi dati — per ulteriori analisi, modellazioni, visualizzazioni o integrazioni in altri progetti — deve includere la citazione del lavoro originale:

Richiardi, C., Caroscio, L., Crescini, E., De Marchi, M., De Pieri, G. M., Ceresi, C., Baldo, F., Francobaldi, M., & Pappalardo, S. E. (2025). A global downstream approach to mapping surface urban heat islands using open data and collaborative technology.
*Sustainable Geosciences: People, Planet and Prosperity*, 100006. [https://doi.org/10.1016/j.susgeo.2025.100006](https://doi.org/10.1016/j.susgeo.2025.100006).

La mancata citazione della pubblicazione originale costituisce una violazione degli standard accademici e professionali.

## Progetto

Il progetto si allinea con l’Obiettivo di Sviluppo Sostenibile n.17 (Partnership per gli obiettivi), promuovendo la collaborazione aperta e intersettoriale attraverso i principi della scienza aperta.
Rilasciando il workflow sotto licenza GNU General Public License v3.0 (GPL 3.0) e fornendo implementazioni sia in R che in Python, il progetto incoraggia l’inclusività nello sviluppo tecnico e nell’utilizzo dei risultati.

Nel rispetto dei valori di trasparenza, riproducibilità e accessibilità, tutto il codice, i passaggi di elaborazione e la documentazione sono condivisi pubblicamente per facilitare la collaborazione tra istituzioni di ricerca, settori politici e regioni geografiche differenti.
La repository è concepita come una risorsa “viva”, che incoraggia i contributi della comunità, l’interoperabilità tra strumenti e la co-creazione di analisi ambientali robuste a supporto di decisioni basate su evidenze scientifiche.

## Ringraziamenti

Lo sviluppo di questo workflow è stato reso possibile grazie alla collaborazione e al supporto di **SCIFT Officina**.  
Per domande o contributi, apri una issue, invia una pull request o contattaci via mail.  

# 💬 Non dimenticare di condividere il tuo feedback!
Ci piacerebbe sapere come utilizzi il flusso di lavoro. Il tuo contributo ci aiuta a migliorarlo e a metterne in evidenza le applicazioni nel mondo reale.  
  <
👉 Dedica qualche minuto alla compilazione del nostro [modulo di feedback utente](https://docs.google.com/forms/d/e/1FAIpQLScPsFdDerNaYa_WPHlRN-0qV5SfJcZ4uILIQK0cef_2M6jNOg/viewform?usp=dialog).

Se lo desideri, puoi anche condividere la tua esperienza sull'utilizzo del flusso di lavoro e sull'impatto dei risultati ottenuti.
Grazie per il tuo contributo nel rendere questo progetto più aperto, utile e collaborativo! 🌍
    
