﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SearchFunction
{
    internal static class Validator
    {
        public static bool IsValid<T>(this T value, out IEnumerable<string> validationErrors, bool validateAllProperties = false)
            where T : class
        {
            var validationResult = new List<ValidationResult>();
            var valid = System.ComponentModel.DataAnnotations.Validator.TryValidateObject(value, new ValidationContext(value), validationResult, validateAllProperties);

            validationErrors = validationResult.Select(x => x.ErrorMessage);

            return valid;

        }


    }
}
