import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { TEMPLATE_CONFIG } from '../config/template.config';

interface SplashScreenProps {
  onComplete: () => void;
}

const SplashScreen: React.FC<SplashScreenProps> = ({ onComplete }) => {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    // Animate progress smoothly over 3 seconds
    const duration = 3000;
    const intervalTime = 30;
    const steps = duration / intervalTime;
    let currentStep = 0;

    const timer = setInterval(() => {
      currentStep++;
      setProgress((currentStep / steps) * 100);

      if (currentStep >= steps) {
        clearInterval(timer);
        setTimeout(onComplete, 200); // slight delay after reaching 100%
      }
    }, intervalTime);

    return () => clearInterval(timer);
  }, [onComplete]);

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-white">
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5 }}
        className="flex flex-col items-center w-full max-w-5xl px-8"
      >
        <div className="mb-12 w-full flex items-center justify-center">
          {/* Logo */}
          <img 
            src={TEMPLATE_CONFIG.logos.splash} 
            alt={TEMPLATE_CONFIG.appName} 
            className="w-full max-w-[880px] object-contain drop-shadow-2xl rounded-[20px]"
            onError={(e) => {
              (e.target as HTMLImageElement).src = `https://placehold.co/400x150?text=${encodeURIComponent(TEMPLATE_CONFIG.logos.fallbackText)}`;
            }}
          />
        </div>
        
        {/* Progress Bar Container */}
        <div className="w-full max-w-md h-1.5 bg-gray-100 rounded-full overflow-hidden">
          <motion.div
            className={`h-full ${TEMPLATE_CONFIG.colors.splashProgressBar} rounded-full`}
            style={{ width: `${progress}%` }}
          />
        </div>
        <p className="mt-4 text-sm font-medium text-gray-400 font-sans">
          {TEMPLATE_CONFIG.splash.loadingText} {Math.round(progress)}%
        </p>
      </motion.div>
    </div>
  );
};

export default SplashScreen;
