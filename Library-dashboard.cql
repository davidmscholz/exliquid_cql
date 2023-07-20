library "Library-dashboard"
using FHIR version '4.0.0'
include FHIRHelpers version '4.0.0'

codesystem SampleMaterialType: 'https://fhir.bbmri.de/CodeSystem/SampleMaterialType'

context Patient

define Aliquot: 
  [Specimen] S
  where not (S.identifier.system contains 'http://dktk.dkfz.de/fhir/sid/exliquid-specimen') 
    and S.container.specimenQuantity.value > 0

define AliquotGroupReferences: 
  flatten Aliquot S
  return S.parent.reference

define AliquotGroup:
  [Specimen] S
  where not (S.identifier.system contains 'http://dktk.dkfz.de/fhir/sid/exliquid-specimen')
    and not exists S.collection.quantity.value
    and not exists S.container.specimenQuantity.value
    and AliquotGroupReferences contains S.id

define PrimarySampleReferences:
  flatten AliquotGroup S
  return S.parent.reference

define ExliquidSpecimenWithAliquot:
  from [Specimen] PrimarySample
  where PrimarySample.identifier.system contains 'http://dktk.dkfz.de/fhir/sid/exliquid-specimen'
  and PrimarySampleReferences contains PrimarySample.id

define InInitialPopulation:  
  exists ExliquidSpecimenWithAliquot

define retrieveCondition:
 First(from [Condition] C
  return C.code.coding.where(system = 'http://fhir.de/CodeSystem/bfarm/icd-10-gm').code.first())

define Diagnosis:
  if (retrieveCondition is null) then 'unknown' else retrieveCondition

define function SampleType(specimen FHIR.Specimen):
  specimen.type.coding.where(system = 'https://fhir.bbmri.de/CodeSystem/SampleMaterialType').code.first()
