-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, nppes_provider_last_org_name, nppes_provider_first_name
ORDER BY claims DESC
LIMIT 10;
--answer 1881634483, 99707 claims
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY claims DESC
LIMIT 10;
--answer: Bruce Pendley, Family Practice, with 99707 claims

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count) AS claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY claims DESC;
--answer: Family Practice with 9752347 claims

--     b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) AS opioid_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name) 
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY opioid_claims DESC;
--answer: Nurse Practitioner, with 900,845 claims

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count) AS claims
FROM prescriber
FULL JOIN prescription
USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL
ORDER BY specialty_description;
--answer: yes there are 15 such specialties

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
--Matt's Answer:
WITH claims AS 
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_claims
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	GROUP BY pr.specialty_description),
-- second CTE for total opioid claims
opioid AS
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_opioid
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE drug.opioid_drug_flag ='Y'
	GROUP BY pr.specialty_description)
--main query
SELECT
	claims.specialty_description,
	COALESCE(ROUND((opioid.total_opioid / claims.total_claims * 100),2),0) AS perc_opioid
FROM claims
LEFT JOIN opioid
USING(specialty_description)
ORDER BY perc_opioid DESC;

--Dibran's Answer:
SELECT
	specialty_description,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	
	SUM(total_claim_count) AS total_claims,
	
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
--order by specialty_description;
order by opioid_percentage desc


-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost) AS cost
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY cost DESC;
--answer: INSULIN GLARGINE,HUM.REC.ANLOG, with cost of $104,264,066.35

--     b. Which drug (genoeric_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this wrks.**

SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS cost
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY cost DESC;
--answer: C1 ESTERASE INHIBITOR is the most expensive at $3,495.22 total day supply

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT drug_name,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_type, COUNT(DISTINCT drug_name)AS num_of_drugs, CAST(SUM(total_drug_cost) AS MONEY) AS money 
FROM(SELECT drug_name,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug) AS drug_types
LEFT JOIN prescription
USING(drug_name)
GROUP BY drug_type
ORDER BY money DESC;
--answer: more total money was spent on antibiotics, but there are also more different types of antibiotics. If you go by averages the opioids are higher (276 vs. 350)

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa 
INNER JOIN fips_county
USING(fipscounty)
WHERE state LIKE '%TN%'
--answer: 42 total, 10 distinct

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population
USING(fipscounty)
INNER JOIN fips_county
USING(fipscounty)
WHERE state LIKE '%TN%'
GROUP BY cbsaname
ORDER BY total_pop DESC;
--answer: Nashville-Davidson-Murfreesboro-Franklin has the largest pop with 1,830,410 people. Morristown has the smallest with 116,352. Note that because the cbsaname column is overlapped by multiple counties, I had to sum the population counts (which are broken up by county). 
--Same answer with only one join: 
SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
INNER JOIN population
ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY total_population DESC;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT DISTINCT county, state, population 
FROM population
INNER JOIN fips_county
USING(fipscounty)
FULL JOIN cbsa
USING(fipscounty)
WHERE cbsaname IS NULL
ORDER BY population DESC;
--answer: Sevier County with 95,523 people is the largest county not represented in the cbsa names. 
--another way to answer this one is: 
SELECT SUM(population.population) AS population, fips_county.county
FROM fips_county
LEFT JOIN cbsa
	ON fips_county.fipscounty = cbsa.fipscounty
LEFT JOIN population
	ON fips_county.fipscounty = population.fipscounty
WHERE cbsa.cbsa IS NULL
AND population IS NOT NULL
GROUP BY fips_county.county, population
ORDER BY population DESC;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000
ORDER BY total_claim_count;
--answer: it looked like 9 at first but there were some duplicates so I combined them. There are 7

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, 
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid'
		END AS drug_type
FROM prescription
LEFT JOIN drug
USING(drug_name)
WHERE total_claim_count > 3000
ORDER BY total_claim_count;
--answer: 2 are opioids, 7 are not

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count, 
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid'
		END AS drug_type
FROM prescription
FULL JOIN drug
USING(drug_name)
FULL JOIN prescriber
USING (npi)
WHERE total_claim_count > 3000
ORDER BY nppes_provider_last_org_name;
--answer: David Coffey and Bruce Pendley prescribe the majority of med over 3000, Coffey is responsible for most opioids on this list

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' --prescriber
	AND nppes_provider_city = 'NASHVILLE' --prescriber
	AND opioid_drug_flag = 'Y' --drug
ORDER BY drug_name;
--answer 35 rows represent the number of different opioids prescribed by unique pain management specialists in Nashville. 

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT p1.npi, d.drug_name, p2.total_claim_count
FROM prescriber p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' --prescriber
	AND nppes_provider_city = 'NASHVILLE' --prescriber
	AND opioid_drug_flag = 'Y' --drug
ORDER BY total_claim_count;
--answer: run the query
--another way to do this is: 
SELECT
	prescriber.npi,
	drug.drug_name,
	(SELECT
	 	SUM(prescription.total_claim_count)
	 FROM prescription
	 WHERE prescriber.npi = prescription.npi
	 AND prescription.drug_name = drug.drug_name) as total_claims
FROM prescriber
CROSS JOIN drug  -- use a cross and an inner
INNER JOIN prescription
using (npi)
WHERE 
	prescriber.specialty_description = 'Pain Management' AND
	prescriber.nppes_provider_city = 'NASHVILLE' AND
	drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name
ORDER BY prescriber.npi DESC;

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT p1.npi, d.drug_name, COALESCE(p2.total_claim_count,0)
FROM prescriber p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' --prescriber
	AND nppes_provider_city = 'NASHVILLE' --prescriber
	AND opioid_drug_flag = 'Y' --drug
ORDER BY total_claim_count;
--answer: run the query