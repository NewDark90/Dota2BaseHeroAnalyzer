using System;
using System.Collections.Generic;
using System.Text;

namespace BaseHeroAnalyzer.Core.Models
{
    public class Hero
    {
        public Stat<decimal> StrengthBase { get; set; }
        public Stat<decimal> AgilityBase { get; set; }
        public Stat<decimal> IntellegenceBase { get; set; }
        public Stat<decimal> StrengthGain { get; set; }
        public Stat<decimal> AgilityGain { get; set; }
        public Stat<decimal> IntellegenceGain { get; set; }
        public Stat<decimal> ArmorBase { get; set; }
        public Stat<decimal> MovementSpeedBase { get; set; }
        public Stat<decimal> DamageBase { get; set; }

        //etc
    }
}
