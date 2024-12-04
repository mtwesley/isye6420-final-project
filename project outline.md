# Title Here

### Abstract 

Understanding the determinants of climate-related disasters, such as floods and storms, is critical in the context of increasing climate variability and its socio-economic impacts. This study explores the application of hierarchical Bayesian modeling to investigate the relationships between climate variables, extreme weather events, and disaster occurrences. Using a comprehensive dataset of global climate and disaster indicators, we build models to analyze how average temperature, precipitation, and their extremes influence disaster frequency.

Two modeling approaches are compared: one using normal distributions to describe disaster outcomes as continuous variables, and another employing exponential transformations and Poisson distributions to better capture the discrete and count-based nature of disasters. We evaluate the performance of these methods in terms of parameter estimates, model convergence, and interpretability. While the normal approach offers simplicity and intuitive parameterization, the Poisson-based method is better suited for modeling rare events but requires careful handling of over-dispersion and scaling.

The research highlights the challenges of working with real-world datasets, including data availability, temporal alignment, and variable selection. The analysis reveals significant relationships between climate variables and disasters, providing insights into potential risk factors. Although migration data was initially considered for inclusion, it remains an area for future integration due to its temporal granularity.





Bayesian statistics project to model the effects of climate change on natural disasters

focusing on floods and storms due to data reliability

application of hierarchical Bayesian modeling to investigate the relationships

 Using a comprehensive dataset of global climate and disaster indicators, we build models to analyze how average temperature, precipitation, and their extremes influence disaster frequenc

two modeling approaches are compared: one using normal distributions to describe disaster outcomes as continuous variables, and another employing exponential transformations and Poisson distributions to better capture the discrete and count-based nature of disasters

evaluate the performance of these methods

highlights the challenges of working with real-world datasets, including data availability, temporal alignment, and variable selection









Intro

- inital goal was to measure the causal relationship between climate change and migration
- to measure this i wanted to use natural disasters to identify situations where climate change events were extreme
- intitially wanted to measure how this impacted migration 
- i explored methods using regression discontinuality and diffference in differences
- i wanted to use Bayesian heirarchial modeling to map the relationship between climate change to natural disasters and from natural disasters to migration
- however, i wasn’t able to find enough data, despite spending an enormous amount of time looking for data and mangling it
- in the end, the migration data did not support my methods and it would take a substatial amount of time to complete the project
- so i simplified it and salvaged what i had a a model that was able to map the relationship between climate change and natural disasters using Bayesian hiearchail modeling
- in the future i may be able to complete the rest of the project



Methods

- I researched data sets on climate change, natural disaters and migration
- [list the many differenet sources – and discuss them] 
- i settled on EM-DAT for natural disasters
- NAOO NCEI GSOY for climate variables
  - although i investigated many others, including the GSOM which was very large
  - i found out that many of the datasets available are from sattelite imagery and were difficult to work with
- i used UNDESA dataset for migration 
  - there were many other data sets, but they wer difficult to work iwth
  - migration is also dififcult to under stand for many reasons – you can list them here
- 



Data

* eventually i have this data
* countless hours in wrangling the data
* using bash scripts, R scripts, editing and double checking, pulling data from APIs
* managed to filter the data to make sure i had enough variation across countries and remove missing data in reasonable ways
* in the end i settled on some final datasets



Models and Results

* to create hiearachial models
* combinging the data together
* testing differnet models. starting at simple models and then more complex models
* eventually testing the output



Setbacks

* spending a lot of time looking for migration data and yet not being able to use it
* model complexities, convergence issues
* difficulty ensuring i had enough time



Results

* version of the model using exp() and and poisson()
* version of the model using normal()



Comparative Analysis

* Comparision of the models



Conclusion

* in the end, this is more of a project related to real life working with real data
* the complexities and difficulties in gathering, compiling, and organizing data that isn’t perfectly suited for workflows
* in the end, i still ended up with some Bayesian analysis, but which i could do more
* the data speaks for itself, the results are decent
* the project was ambitious and i would continue it in the future