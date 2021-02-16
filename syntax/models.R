library(tidyverse, quietly = TRUE)
library(lme4)

evs <- read_rds("data/evs-clean-with-Cr.rds")

# Standardize variables 

evs <- evs %>%
  mutate(just_bin = ifelse(just > 1, 1, 0),
         just_log = ifelse(just > 1, log(just), NA_real_)) %>%
  group_by(id) %>%
  mutate(style_just = mean(just),
         style_common = mean(common),
         female = ifelse(sex == "Female", 1, 0),
         edu_mid = ifelse(edu == "middle", 1, 0),
         edu_high = ifelse(edu == "high", 1, 0)) %>%
  ungroup()

scale <- function(x) {
  (x - mean(x, na.rm = TRUE))/(sd(x, na.rm = TRUE))
}

scale_range <- function(x) {
  (x - min(x))/max(x - min(x))
}

evs_c <- evs %>%
  group_by(cntry) %>%
  # center common at the country mean
  mutate(relig = relig - mean(relig),
         age = age/10) %>%
  mutate_at(vars(age, female:edu_high),  ~ . - mean(.)) %>%
  group_by(cntry, id) %>%
  mutate(common_i = common - mean(common)) %>%
  group_by(behaviour, cntry) %>%
  # center common at the country mean
  mutate(common = common - mean(common)) %>%
  ungroup()

# evs_2l_sc <- evs %>%
#   group_by(behaviour) %>% 
#   mutate(mean_just = mean(just), 
#          sd_just = sd(just)) %>% 
#   mutate_at(vars(just, just_log), scale) %>% 
#   group_by(behaviour, cntry) %>% 
#   mutate(mean_common = mean(common),
#          sd_common = sd(common),
#          mean_relig = mean(relig),
#          sd_relig = sd(relig)) %>% 
#   mutate_at(vars(common, relig, age),
#             scale) %>% 
#   mutate_at(vars(female:edu_high),  ~ . - mean(.)) %>% 
#   ungroup()

# evs_3l_sc <- evs %>%
#   mutate(mean_just = mean(just), 
#          sd_just = sd(just)) %>% 
#   mutate_at(vars(just, just_log), scale) %>% 
#   group_by(cntry) %>% 
#   mutate_at(vars(relig, age),
#             scale) %>% 
#   mutate_at(vars(female:edu_high),  ~ . - mean(.)) %>% 
#   group_by(cntry, id) %>% 
#   mutate(common_i = scale(common),
#          common_c = common - mean(common)) %>% 
#   ungroup()

# Three-level model


m <- lmer(just ~ common_i + relig + common_i:relig + 
             female + age + edu_mid + edu_high + 
             (1 + common_i|cntry/id),
           evs_c,
           control = lmerControl(optimizer = "bobyqa"),
           REML = TRUE)

m2.1 <- glmer(just_bin ~ common_i + relig + common_i:relig + 
            female + age + edu_mid + edu_high + 
            (1 + common_i|cntry/id),
          evs_c,
          family = binomial(),
          control = glmerControl(optimizer = "bobyqa"))

m2.2 <- lmer(just_log ~ common_i + relig + common_i:relig + 
               female + age + edu_mid + edu_high + 
               (1 + common_i|cntry/id),
             evs_c,
             control = lmerControl(optimizer = "bobyqa"),
             REML = TRUE)


list("M1. Baseline" = m, 
    "M2.1. logit(p_Mo>1)" = m2.1, 
    "M2.2. log(Mo)|Mo > 1" = m2.2) %>% 
  write_rds("data/mixed-3l-models.rds")


by_behav <- evs_c %>% 
  group_by(behaviour) %>% 
  nest()

fit_model <- function(data, ...) {
  lmer(just ~ common + relig + common:relig + 
         female + age + edu_mid + edu_high +
         (1 + common|cntry),
       data, control = lmerControl(optimizer = "bobyqa"), ...)
}

by_behav <- by_behav %>% 
  mutate(mod = map(data, fit_model, REML = TRUE))

fit_bin_model <- function(data, ...) {
  glmer(just_bin ~ common + relig + common:relig +
          female + age + edu_mid + edu_high +
          (1 + common|cntry),
        family = binomial(),
       data, control = glmerControl(optimizer = "bobyqa"), ...)
}

# Two-part model: M2.1 and M2.2
by_behav <- by_behav %>% 
  mutate(mod_tob_1 = map(data, fit_bin_model),
         mod_tob_2 = map(mod, ~update(.x, just_log ~ . )))

write_rds(by_behav, "data/mixed-2l-models.rds")

# 
# 
# by_behav %>% 
#   mutate(bic = map_dbl(mod, BIC), 
#          bic2 = map_dbl(mod2, BIC),
#          bic3 = map_dbl(mod3, BIC),
#          bic4 = map_dbl(mod4, BIC),
#          bic_s = map_dbl(mod_s, BIC),
#          bic_s2 = map_dbl(mod_s2, BIC)) %>% 
#   transmute(bic - bic2)


# m2 <- lmer(just ~ common_i + relig + common_i:relig + 
#              female + age + edu_mid + edu_high + 
#              (1 + common_i + relig|cntry/id),
#            evs_3l_sc,
#            #          control = lmerControl(optimizer = "bobyqa"),
#            REML = FALSE)
# 
# system.time(m3 <- lmer(just ~ common_i + relig + common_i:relig + 
#                          female + age + edu_mid + edu_high + 
#                          (1 + common_i + relig + common_i:relig|cntry/id),
#                        evs_c,
#                        #          control = lmerControl(optimizer = "bobyqa"),
#                        REML = FALSE))
# anova(m, m2)
# anova(m3, m2)
# 
# modelplot(list(m, m2, m3), coef_omit = "Obs")
# 
# broom.mixed::tidy(m, effects = "fixed")
# 
# save(m, m2, m3, file = "data/3-level-models.Rdata")
# load(file = "data/3-level-models.Rdata")
