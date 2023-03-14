using SearchFunction.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction.Services
{
    public class QueryRequestValidationService
    {
        /// <summary>
        /// This validation method is used to validate the QueryRequest object
        /// to check that either SearchParameter or FilterOptions is present
        /// if neither are present then the request is invalid. If either property
        /// is present then the object is validated using the DataAnnotations and
        /// Validator class.
        /// </summary>
        /// <param name="queryRequest"></param>
        /// <param name="validationResults"></param>
        /// <param name="validateAllProperties"></param>
        /// <returns></returns>
        public bool Validate(QueryRequest queryRequest, out IList<ValidationResult> validationResults, bool validateAllProperties)
        {
            validationResults = new List<ValidationResult>();
            
            if (string.IsNullOrEmpty(queryRequest.SearchParameter) && string.IsNullOrEmpty(queryRequest.FilterOptions))
            {
                var noPropertiesError = new ValidationResult("At least one property must be specified in your request"
                                                            , new[] { "SearchParameters", "FilterOptions" });
                validationResults.Add(noPropertiesError);
            }
            else
            {// if either property is present validate object using DataAnnotations and Validator class
                // validate object using DataAnnotations and Validator class
                Validator.TryValidateObject(queryRequest, new ValidationContext(queryRequest), validationResults, validateAllProperties);
            }

            return validationResults.Count > 0;
        }
    }
}