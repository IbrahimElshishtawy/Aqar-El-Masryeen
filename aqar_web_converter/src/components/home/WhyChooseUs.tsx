import React from 'react';
import { ShieldCheck, Receipt, BarChart3, Users, Building2, CheckCircle2 } from 'lucide-react';

export function WhyChooseUs() {
  const features = [
    {
      title: 'إدارة تشوينات ومصروفات دقيقة',
      desc: 'حصر دقيق لمواد البناء، الموردين، وتكاليف العمالة والتشطيبات لحظة بلحظة مع ربطها بالوحدات والمشروعات.',
      icon: Receipt,
    },
    {
      title: 'حسابات وتسويات الشركاء',
      desc: 'توزيع الأرباح ورؤوس الأموال بحسب نسب الملكية وحصص كل شريك، مع إشعارات آلية عند كل تحصيل.',
      icon: Users,
    },
    {
      title: 'جداول أقساط ذكية',
      desc: 'متابعة مواعيد استحقاق الشيكات والأقساط، كشوف حساب عملاء فورية، وسجل سداد غير قابل للتلاعب.',
      icon: BarChart3,
    },
    {
      title: 'أعلى درجات الأمان والاعتمادية',
      desc: 'قاعدة بيانات سحابية مشفرة تستحمل آلاف العمليات المتزامنة وتمنحك تقارير مالية جاهزة للطباعة والاعتماد.',
      icon: ShieldCheck,
    },
  ];

  return (
    <section id="about" className="py-16 sm:py-24 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto text-center mb-12 sm:mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#EBE8E1] text-[#777777] text-xs font-bold mb-3">
          <ShieldCheck className="w-3.5 h-3.5 text-[#A89F91]" />
          <span>ركائز التميز المؤسسي</span>
        </div>
        <h2 className="font-editorial text-2xl sm:text-4xl font-black text-[#242424]">
          لماذا يختار المستثمرون عقار المصريين؟
        </h2>
        <p className="text-xs sm:text-sm text-[#777777] mt-2">
          منظومة متكاملة تضمن للمشتري راحة البال، وللمستثمر والشريك العائد الأعلى والشفافية التامة.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {features.map((feat, i) => {
          const Icon = feat.icon;
          return (
            <div
              key={i}
              className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] hover:border-[#A89F91] transition duration-200 space-y-3"
            >
              <div className="w-12 h-12 rounded-2xl bg-[#242424] text-[#F4F4F2] flex items-center justify-center">
                <Icon className="w-6 h-6 text-[#A89F91]" />
              </div>
              <h3 className="text-base font-bold text-[#242424] pt-2">{feat.title}</h3>
              <p className="text-xs text-[#777777] leading-relaxed">{feat.desc}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}
