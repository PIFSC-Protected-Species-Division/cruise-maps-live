
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Near Real-Time Cetacean Cruise Maps

<img
src="README_files/figure-gfm/fa-icon-bcbd573b0c4bf742a1242819bebaac28.svg"
style="width:0.88em;height:1em" /> *Last Update: 05 Jul 2023*

<img
src="README_files/figure-gfm/fa-icon-d8ea6ac07fd86570bd4146f5874f7163.svg"
style="width:1.12em;height:1em" /> *This code is always in development*

## Developers

**Janelle Badger** (janelle.badger AT noaa.gov)  
**Yvonne Barkley** (yvonne.barkley AT noaa.gov)  
**Selene Fregosi** (selene.fregosi AT noaa.gov)  
**Kym Yano** (kym.yano AT noaa.gov)

Cetacean Research Program \| Protected Species Division  
Pacific Islands Fisheries Science Center  
National Marine Fisheries Service  
National Oceanic and Atmospheric Administration

The idea for these live maps and this repository was inspired by the
Alaska Fisheries Science Center’s live survey maps. The code and outputs
presented here are modified from the AFSC team’s
[survey-live-temperature-map](https://github.com/afsc-gap-products/survey-live-temperature-map)
repository.

## Purpose

The Hawaiian Islands Cetacean and Ecosystem Survey (HICEAS) assesses
whale, dolphin, and seabird populations across the Hawaiian Islands. The
survey is conducted by NOAA Fisheries’ Pacific Islands Fisheries Science
Center. The code in this repository allows us to generate summary maps
and tables of our survey progress and cetacean sightings. These scripts
compile the various data streams, collected and uploaded to Google Drive
by the researchers at sea, and then create daily maps and an up-to-date
summary table. The generated map and table are shared to the cruise
website.

- [HICEAS 2023 is
  Underway!](https://storymaps.arcgis.com/stories/b3bbf0e90d0141f7bf47edc5339ccb7a)

## Notes

[How to set up the task
scheduler](https://docs.google.com/document/d/1pwBmR6AqgnvUx_AiWYQxtYxIRjWMfdd5EPWwFvpI3Ug/edit)
*( thank you Emily!)*

Where the input and output files will be saved: [Google Drive -
Restricted
access](https://drive.google.com/drive/u/0/folders/1okUHW9LRxXJ8T8Djxu_VUKV3LPmEMp6c)

When running the `run.R` script for the first time on your local
machine, first run the `prep.R` script to ensure the folder structure is
set up properly and all necessary packages are installed.

## Plot Examples

As each survey leg completes we will share some example plots and gifs
here!

### Blank, pre-survey base map

![HICEAS 2023 Base Map, A bathymetric map of the HICEAS study area and
the planned transect lines. The U.S. Exclusive Economic Zone (EEZ)
surrounding the Hawaiian archipelago (study area) is marked with a white
boundary line and planned transect lines are in thin black lines. The
Papahānaumokuākea Marine National Monument area and Main Hawaiian
Islands are labeled in white text. The transect lines run lengthwise
from northwest to southeast, covering the entire EEZ. This map image
does not show any completed survey tracklines or cetacaen sightings but
serves as the basemap that will be populated with this information as
the survey gets
underway.](./outputs/hiceas-2023-cruise-map_placeholder.png)

## Suggestions and Comments

If you see that the data, product, or metadata can be improved, you are
invited to create a [pull
request](https://github.com/PIFSC-Protected-Species-Division/cruise-maps-live/pulls),
or [submit an issue to this
repository](https://github.com/PIFSC-Protected-Species-Division/cruise-maps-live/issues)

## R Version Metadata

    FALSE R version 4.3.0 (2023-04-21 ucrt)
    FALSE Platform: x86_64-w64-mingw32/x64 (64-bit)
    FALSE Running under: Windows 10 x64 (build 19045)
    FALSE 
    FALSE Matrix products: default
    FALSE 
    FALSE 
    FALSE locale:
    FALSE [1] LC_COLLATE=English_United States.utf8 
    FALSE [2] LC_CTYPE=English_United States.utf8   
    FALSE [3] LC_MONETARY=English_United States.utf8
    FALSE [4] LC_NUMERIC=C                          
    FALSE [5] LC_TIME=English_United States.utf8    
    FALSE 
    FALSE time zone: America/Los_Angeles
    FALSE tzcode source: internal
    FALSE 
    FALSE attached base packages:
    FALSE [1] stats     graphics  grDevices utils     datasets  methods   base     
    FALSE 
    FALSE other attached packages:
    FALSE [1] fontawesome_0.5.1
    FALSE 
    FALSE loaded via a namespace (and not attached):
    FALSE  [1] compiler_4.3.0  fastmap_1.1.1   cli_3.6.1       tools_4.3.0    
    FALSE  [5] htmltools_0.5.5 rstudioapi_0.14 rsvg_2.4.0      yaml_2.3.7     
    FALSE  [9] rmarkdown_2.22  knitr_1.43      xfun_0.39       digest_0.6.31  
    FALSE [13] rlang_1.1.1     evaluate_0.21

## NOAA Disclaimer and License

<sub>This repository is a scientific product and is not official
communication of the National Oceanic and Atmospheric Administration, or
the United States Department of Commerce. All NOAA GitHub project code
is provided on an ‘as is’ basis and the user assumes responsibility for
its use. Any claims against the Department of Commerce or Department of
Commerce bureaus stemming from the use of this GitHub project will be
governed by all applicable Federal law. Any reference to specific
commercial products, processes, or services by service mark, trademark,
manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of Commerce.
The Department of Commerce seal and logo, or the seal and logo of a DOC
bureau, shall not be used in any manner to imply endorsement of any
commercial product or activity by DOC or the United States Government.

<sub>Software code created by U.S. Government employees is not subject
to copyright in the United States (17 U.S.C. §105). The United
States/Department of Commerce reserve all rights to seek and obtain
copyright protection in countries other than the United States for
Software authored in its entirety by the Department of Commerce. To this
end, the Department of Commerce hereby grants to Recipient a
royalty-free, nonexclusive license to use, copy, and create derivative
works of the Software outside of the United States.

<img src="https://raw.githubusercontent.com/nmfs-general-modeling-tools/nmfspalette/main/man/figures/noaa-fisheries-rgb-2line-horizontal-small.png" height="75" alt="NOAA Fisheries">

[U.S. Department of Commerce](https://www.commerce.gov/) \| [National
Oceanographic and Atmospheric Administration](https://www.noaa.gov) \|
[NOAA Fisheries](https://www.fisheries.noaa.gov/)
