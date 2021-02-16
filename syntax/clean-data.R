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
         relig = A006,
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
         # independence = A029,
         # obedience = A042,
         # reverse religiosity item
         relig = 5 - relig,
         edu = cut(edu, 
                   c(0, 3, 6, 8), 
                   labels = c("low", "middle", "high"))) %>% 
  # Reverse the common variables
  mutate_at(vars(starts_with("common")), ~(5 - .))


evs <- evs %>% 
  # Exclude those who did not respect the requirement of no more that 5 child qualities
  mutate(total = rowSums(dplyr::select(., starts_with("A0")), na.rm = TRUE)) %>%
#  filter(total > 0, total <= 5) %>%
#  select(-A027,-A028, -A030:-A038, -A041, -total) %>%
  drop_na(sex, age, edu, relig)


# Reshape behaviors into long format.
evs_long <- evs %>% 
  mutate(id = rownames(.)) %>% 
  gather(var, value, starts_with("just"), starts_with("common")) %>% 
  separate(var, c("type", "behaviour"), sep  = "\\.") %>%
  spread(type, value) %>% 
  drop_na(just, common) 

write_rds(evs_long, "data/evs-clean-with-Cr.rds")
