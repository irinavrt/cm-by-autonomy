library(tidyverse)
library(haven)
library(readxl)

evs_full <- read_sav("data/ZA4804_v3-1-0.sav")

evs  <- evs_full %>%
  filter(as_factor(S002EVS) == "1999-2001") %>% 
  select(cntry = S003, year = S020, wgt = S017, 
         sex = X001,
         age = X003,
         income = X047,
         edu = X025,
         just.state_benef = F114,
         just.tax_cheat = F116,
         just.cash = F131,
         just.drugs = F126,
         just.liter = F129,
         just.speed = F134,
         just.alc_drive = F130,
         just.casual_sex = F132,
# The following three items are only used in a few countries for frequency ratings and therefore excluded from analysis.
#         just.fare_cheat = F115,
#         just.lie = F127,
#         just.bribe = F117,
         common.state_benef = F145,
         common.tax_cheat = F146,
         common.cash = F147,
         common.drugs = F148,
         common.liter = F149,
         common.speed = F150,
         common.alc_drive = F151,
         common.casual_sex = F152,
#         common.fare_cheat = F153,
#         common.lie = F154,
#         common.bribe = F155,
         A027:A042) 


evs <- evs %>% 
  mutate_at(vars(cntry, sex), as_factor) %>% 
  zap_labels() %>% 
  mutate(cntry = as.character(cntry),
         autonomy = A029 + A039 - A042 - A040, 
         aut_short = (A029 + (1-A042))/2,
         edu = cut(edu, 
                   c(0, 3, 6, 8), 
                   labels = c("low", "middle", "high"))) %>% 
  # Reverse the common variables
  mutate_at(vars(starts_with("common")), ~(5 - .))


evs <- evs %>% 
  # Exclude those who did not respect the requirement of no more that 5 child qualities
  mutate(total = rowSums(dplyr::select(., starts_with("A0")), na.rm = TRUE)) %>% 
  filter(total > 0, total <= 5) %>% 
  select(-A027,-A028, -A030:-A038, -A041, -total) %>% 
  drop_na(sex, age, edu, autonomy)


# Reshape behaviours into long format.
evs_long <- evs %>% 
  mutate(id = rownames(.)) %>% 
  gather(var, value, starts_with("just"), starts_with("common")) %>% 
  separate(var, c("type", "behaviour"), sep  = "\\.") %>%
  spread(type, value) %>% 
  drop_na(just, common) 


# Country level data ----------------------------------------------------------------

# Country level autonomy
evs_long <- evs_long %>% 
  group_by(cntry) %>% 
  mutate(autonomy_cntry = weighted.mean(autonomy, wgt, na.rm = TRUE),
         aut_sh_cntry = weighted.mean(aut_short, wgt, na.rm = TRUE)) %>% 
  ungroup()

# Add country codes to merge HDI data
cntry_codes <- read_csv("data/cntry-codes.csv")
evs_long <- left_join(evs_long, cntry_codes %>% select(cntry = evs_name, code)) 


# HDI
hdi <- read_csv("data/GDL-Indices-(1999)-data.csv")

evs_long <- left_join(evs_long, 
                 hdi %>% 
                   select(code = ISO_Code,
                          hdi_gni = `Income index`,
                          hdi_edu = `Educational index`,
                          hdi_health = `Health index`))



write_rds(evs_long, "data/evs-clean.rds")
