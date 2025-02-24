source(here::here("R/build/attach-packages.R"))
suppressPackageStartupMessages(suppressWarnings(suppressMessages(library(tabulizer))))

message(glue("{Sys.time()} -- Starting download of NYS nursing home deaths"))

url <- "https://www.health.ny.gov/statistics/diseases/covid-19/fatalities_nh.pdf"
file <- paste0("data/nh-pdf/nys-nursing-home-", Sys.Date(), ".pdf")
download.file(url, file, mode = "wb", quiet = TRUE)

date <- extract_text(file, pages = 1) %>% 
  str_extract("Data through .*") %>% 
  mdy()

nh_deaths <- extract_tables(file, pages = 3:22) %>%
  map_dfr(as.data.frame) %>%
  filter(!V2 %in% c("", "NH PFI")) %>% 
  transmute(
    date = date,
    name = V1,
    pfi = V2,
    county = V3,
    deaths_confirmed = as.numeric(V4),
    deaths_hosp_confirmed = as.numeric(V5),
    deaths_presumed = as.numeric(V6)
  ) %>% 
  mutate(
    name = case_when(
      name == "NORTH WESTCHESTER RESTORATIVE THERAPY AND NURSING" ~ "NORTH WESTCHESTER RESTORATIVE THERAPY AND NURSING CENTER",
      name == "THE PARAMOUNT AT SOMERS REHABILITATION AND NURSING" ~ "THE PARAMOUNT AT SOMERS REHABILITATION AND NURSING CENTER",
      name == "YONKERS GARDENS CENTER FOR NURSING AND" ~ "YONKERS GARDENS CENTER FOR NURSING AND REHABILITATION",
      TRUE ~ name
      ),
    name = str_to_title(name),
    name = str_replace(name, "\r", " ")
    ) %>% 
  filter(str_detect(county, "Westch")) %>% 
  select(-county)

write_csv(nh_deaths, "data/nursing-home-deaths.csv")

message(glue("Most recent data is from {date}"))
message(glue("{Sys.time()} -- Finished download of NYS nursing home deaths"))