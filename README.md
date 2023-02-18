# Live Cetacean Cruise Maps

> Code is always in development. 

## Developers

**Selene Fregosi** (selene.fregosi AT noaa.gov)  
Cetacean Acoustician  

Pacific Islands Fisheries Science Center,  
National Marine Fisheries Service,  
National Oceanic and Atmospheric Administration

The idea for these live maps and this repository was inspired by the Alaska Fisheries Science Center's live survey maps. The code and otuptus presented here are modified from the AFSC team's [survey-live-temperature-map](https://github.com/afsc-gap-products/survey-live-temperature-map) repository. 

## Purpose

These scripts create daily survey maps as the ships work their way through along the Hawaiian Islands. These ships are conducting NOAA Fisheries' Pacific Islands Fisheries Science Center's Hawaiian Islands Cetacean and Ecosystem Assesment Survey (HICEAS). Scripts pull collected data streams from google drive, entered by researchers at sea, create daily maps and composite gifs, and then push the maps to google drive for the communications team. These plots will be displayed on the HICEAS website

 - [Web link will be here](https://)


## Notes

How to set up the task scheduler: https://docs.google.com/document/d/1pwBmR6AqgnvUx_AiWYQxtYxIRjWMfdd5EPWwFvpI3Ug/edit

Where the files will be saved to: https://drive.google.com/drive/folders/1okUHW9LRxXJ8T8Djxu_VUKV3LPmEMp6c

Troubleshooting: if the task scheduler fails to run the code, but you can run the script in R or Rstudio, you may need to update Pandoc. The latest version is here: https://github.com/jgm/pandoc/releases/tag/2.18. If you are on a NOAA machine, ask IT to install the .msi file for you. Close and reopen everything and try again. 

## Plot Examples

### Final combined gifs

![2021 Bering Sea Survey](./test/2021-08-16_daily.gif)

![2018 Aluetian Islands Survey](./test/2021-08-08_daily.gif)

### Blank, Grid-only Plot

![Bering Sea Survey Empty Grid](./test/_grid_bs.png)

![Aluetian Islands Survey Empty Grid](./test/_grid_ai.png)

### Daily Plot

![Daily Temperatrues](./test/2021-06-04_daily.png)

### Anomaly Plot

![Anomaly Temperatrues](./test/2021-06-04_anom.png)

## NOAA README

This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.

## NOAA License

Software code created by U.S. Government employees is not subject to copyright in the United States (17 U.S.C. §105). The United States/Department of Commerce reserve all rights to seek and obtain copyright protection in countries other than the United States for Software authored in its entirety by the Department of Commerce. To this end, the Department of Commerce hereby grants to Recipient a royalty-free, nonexclusive license to use, copy, and create derivative works of the Software outside of the United States.

<img src="https://raw.githubusercontent.com/nmfs-general-modeling-tools/nmfspalette/main/man/figures/noaa-fisheries-rgb-2line-horizontal-small.png" height="75" alt="NOAA Fisheries">

[U.S. Department of Commerce](https://www.commerce.gov/) | [National
Oceanographic and Atmospheric Administration](https://www.noaa.gov) |
[NOAA Fisheries](https://www.fisheries.noaa.gov/)
