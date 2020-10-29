library(tidyverse, quietly = TRUE)
library(lme4)

evs <- read_rds("data/evs-clean.rds")


# Standardize variables 

evs_sc <- evs %>%
  mutate(just_bin = ifelse(just > 1, 1, 0),
         just_log = ifelse(just > 1, log(just), NA_real_)) %>%
  group_by(id) %>%
  mutate(style = mean(just, na.rm = TRUE)) %>%
  group_by(cntry) %>%
  mutate(age  = scale(age)[,1]) %>%
  ungroup() %>%
  mutate_at(vars(starts_with("hdi"), autonomy_cntry, aut_sh_cntry, autonomy, aut_short,
                 common, just, just_log, style),
            ~scale(.)[,1])

# M1. Baseline

m_reml <- lmer(just ~ common + common*autonomy_cntry + common*autonomy + edu + age + sex +
                 common*hdi_edu + common*hdi_gni +
                  (1 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                evs_sc,
             control = lmerControl(optimizer = "bobyqa"),
             REML = TRUE)

m <- lmer(just ~ common + common*autonomy_cntry + common*autonomy + edu + age + sex +
                 common*hdi_edu + common*hdi_gni +
                  (1 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                evs_sc,
             control = lmerControl(optimizer = "bobyqa"),
             REML = FALSE)

# Two-part model: M2.1 and M2.2

m_tob_1 <- glmer(just_bin ~ common + common*autonomy_cntry + common*autonomy + edu + age + sex +
                   common*hdi_edu + common*hdi_gni +
                   (1 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                 evs_sc,
                 family = binomial(),
                 control = glmerControl(optimizer = "bobyqa"))

m_tob_2_reml <- lmer(just_log ~ common + common*autonomy_cntry + common*autonomy + edu + age + sex +
                       common*hdi_edu + common*hdi_gni +
                       (1 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                     evs_sc,
                     control = lmerControl(optimizer = "bobyqa"),
                     REML = TRUE)

m_tob_2 <- lmer(just_log ~ common + common*autonomy_cntry + common*autonomy + edu + age + sex +
                  common*hdi_edu + common*hdi_gni +
                  (1 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                evs_sc,
                control = lmerControl(optimizer = "bobyqa"),
                REML = FALSE)

# M3. Alternative autonomy with two items

m_sh_reml <- lmer(just ~ common +
                  common*aut_sh_cntry + common*aut_short + edu + age + sex +
                 common*hdi_edu + common*hdi_gni +
                  (1 + common|cntry:id) + (1 + common + aut_short + common:aut_short|cntry),
                evs_sc,
             control = lmerControl(optimizer = "bobyqa"),
             REML = TRUE)

m_sh <- lmer(just ~ common +
                  common*aut_sh_cntry + common*aut_short + edu + age + sex +
                 common*hdi_edu + common*hdi_gni +
                  (1 + common|cntry:id) + (1 + common + aut_short + common:aut_short|cntry),
                evs_sc,
             control = lmerControl(optimizer = "bobyqa"),
             REML = FALSE)

# M4. Style factor

m_style_reml <- lmer(just ~ common + common*autonomy_cntry + common*autonomy + style + edu + age + sex +
                 common*hdi_edu + common*hdi_gni +
                  (0 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                evs_sc,
             control = lmerControl(optimizer = "bobyqa"),
             REML = TRUE)

m_style <- lmer(just ~ common + common*autonomy_cntry + common*autonomy + style + edu + age + sex +
                 common*hdi_edu + common*hdi_gni +
                  (0 + common|cntry:id) + (1 + common + autonomy + common:autonomy|cntry),
                evs_sc,
             control = lmerControl(optimizer = "bobyqa"),
             REML = FALSE)



# Assemble models in a data frame with list columns

mixed_models <- tibble(model = c("m1", "m2.2", "m2.2", "m3", "m4"),
                       name = c("M1. Baseline",
                                "M2.1. Part 1, logit(if y > 1)" ,
                                "M2.2. Part 2, log(y)|y > 1",
                                "M3. Two items autonomy",
                                "M4. Style factor"),
                       reml = c(m_reml, m_tob_1, m_tob_2_reml, m_sh_reml, m_style_reml),
                       ml = c(m, m_tob_1, m_tob_2, m_sh, m_style))


write_rds(mixed_models, "data/mixed-models.rds", compress = "gz")
