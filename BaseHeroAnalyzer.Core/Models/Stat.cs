using System;
using System.Collections.Generic;
using System.Text;

namespace BaseHeroAnalyzer.Core.Models
{
    public class Stat<T>
    {
        /// <summary>
        /// Attribute name from file
        /// </summary>
        public string Name { get; set; }
        /// <summary>
        /// Value from the attribute
        /// </summary>
        public T Value { get; set; }

        /// <summary>
        /// Where the hero ranks for the particular stat relative to all heroes. 1st being best. 
        /// </summary>
        public int AllHeroRank { get; set; }
        /// <summary>
        /// The count of other heroes that share the same stat value. IE: 3 heroes tied for 4th place.
        /// </summary>
        public int AllHeroTiedCount { get; set; }
        
        /// <summary>
        /// Where the hero ranks for the particular stat relative to heroes with the same base stat. 1st being best. 
        /// </summary>
        public int PrimaryHeroRank { get; set; }
        /// <summary>
        /// The count of other heroes that share the same stat value within primary attribute. IE: 3 heroes tied for 4th place.
        /// </summary>
        public int PrimaryHeroTiedCount { get; set; }
    }
}
