# Coding Club Tutorial - Zero-inflated Models
# Script Purpose: Zero-inflated models to 
# Zachary Li - s1996567@ed.ac.uk
# Date

# Install packages----
install.packages("ggplot2") 
install.packages("dplyr")
install.packages("MASS") 
install.packages("glmmTMB") 
install.packages("DHARMa")

# Libraries----
library(ggplot2) # create aesthetic visuals from data frame
library(dplyr) # improve data manipulation efficiency
library(MASS) # generate negative binomial regression models
library(glmmTMB) # generate zero-inflated mixed models
library(DHARMa) # allows for zero-inflation testing

# Load Invasive Species Data----
invasive <- read.csv(file = 'data/invasive.csv')

# Visualize the data set
head(invasive)
str(invasive)

# Show the explanatory variable
unique(invasive$Disturbance_Type) 

# Show the response variable
unique(invasive$Bracken_stands)

# Data analysis----
# Create a histogram of initial distribution
# Appears to follow a poisson distribution, with non-negative count data
(hist_invasive <- ggplot(invasive, aes(x = Bracken_stands)) +
    geom_histogram(colour = "black", fill = "#006633", bins = 15) +
    theme_classic() +
    ylab("Frequency\n") +
    ggtitle("Histogram of Bracken Stand Distribution") +
    xlab("\nNumber of bracken stands") +  
    theme(plot.title = element_text(hjust = 0.5, vjust = -8, size = 13)) +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14, face = "plain")))

# Save histogram
ggsave(filename = "figures/bracken_stand_histogram.png", hist_invasive, device = "png")

# Create boxplot of bracken stand distribution according to road type
(bracken_boxplot <- ggplot(invasive, aes(Disturbance_Type, Bracken_stands)) + 
    geom_boxplot(aes(fill = Disturbance_Type)) +
    theme_bw() +
    scale_fill_manual(values = c("#EE7600", "#00868B")) +               # Adding custom colours
    scale_colour_manual(values = c("#EE7600", "#00868B")) +             # Adding custom colours
    ylab("Number of Bracken Stands\n") +                             
    xlab("\nRoad Type")  +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14, face = "plain"),                     
          panel.grid = element_blank(),                                 # Removing the background grid lines               
          plot.margin = unit(c(1,1,1,1), units = , "cm"),               # Adding a margin
          legend.position = "none"))                                    # Removing legend - not needed with only 2 factors

# Save boxplot
ggsave(filename = "figures/bracken_stand_boxplot.png", bracken_boxplot, device = "png")

# Deduce proportion of zeros in the data 
sum(invasive$Bracken_stands == 0)/nrow(invasive) # ~49% of the observations are zeros!

# Basic Poisson model construction----
# Research question: Does the road type (road vs. hiking trail affect the number of bracken stands)?
# Build a basic poisson model
# 'family' symbolizes the type of probability distribution used to model the response variable
summary(poisson_model <- glm(Bracken_stands~Disturbance_Type, data = invasive, family = poisson))

# Check for overdispersion, which is calculated by dividing the residual deviance by the residual degrees of freedom
# Ratio of >4, indicating overdispersion 
# Model fits the data poorly and results cannot be trusted
732.09/178

# Poisson models assume that the variance is equal to the mean
# Visualize and check for mean and variance
# Mean and variance are dramatically different, ratio far >1
# Also indicates overdispersion of the data
mean(invasive$Bracken_stands) %>% round(4) # round to 4 decimal places
var(invasive$Bracken_stands) %>% round (4) # round to 4 decimal places
var(invasive$Bracken_stands)/mean(invasive$Bracken_stands) # calculate ratio between variance and mean 

# Build a null model to compare poisson_model with
mod_null <- glm(Bracken_stands~1, data = invasive, family = poisson)

# Compare model fit between poisson_model and null model using AIC values
# Poisson model fits data better than null model, but is there another suitable model?
AIC(mod_null, poisson_model)

# Negative binomial model construction----
# Negative binomial regression is effective for modelling over-dispersed count variables
# Use the glm.nb() function derived from the MASS package
# This was inspired by https://stats.oarc.ucla.edu/r/dae/negative-binomial-regression/
summary(negbinom_model <- glm.nb(Bracken_stands~Disturbance_Type, data = invasive))

# Compare model fit with Poisson model
AIC(poisson_model, negbinom_model)

# Zero-inflation tests----
mod1 <- glmmTMB(Bracken_stands~Disturbance_Type, family = "poisson", data = invasive) # build model
simulationOutput <- simulateResiduals(fittedModel = mod1) # generate residuals
plot(simulationOutput) # visualize residuals

# Generate Q-Q plot
plotQQunif(simulationOutput = simulationOutput, 
           testDispersion = FALSE,
           testUniformity = FALSE,
           testOutliers = FALSE)

# Test for zero-inflation
testZeroInflation(simulationOutput)

# Zero-inflated models----
# Build zero-inflated negative binomial model using glmmTMB()
zero_inflated_nbiom <- glmmTMB(Bracken_stands ~ Disturbance_Type, ziformula = ~Disturbance_Type, family = "nbinom2", data = invasive)

# Compare model fit with previous models constructed
AIC(poisson_model, negbinom_model, zero_inflated_nbiom)

# Build zero-inflated poisson model
zero_inflated_poisson <- glmmTMB(Bracken_stands ~ Disturbance_Type, ziformula = ~Disturbance_Type, family = "poisson", data = invasive)

# Compare model fit using AIC
AIC(poisson_model, negbinom_model, zero_inflated_poisson, zero_inflated_nbiom)

# Obtain model summary
summary(zero_inflated_nbiom)






